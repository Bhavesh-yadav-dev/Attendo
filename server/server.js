import express from "express";
import multer from "multer";
import cors from "cors";
import axios from "axios";
import FormData from "form-data";
import dotenv from "dotenv";

import db from "./db.js";

dotenv.config();

const app = express();

app.use(express.json());
app.use(cors());

const PORT = process.env.PORT || 8000;

// Max file sizes: 10 MB per registration photo, 20 MB for classroom photo
const REGISTER_MAX_FILE_SIZE = 10 * 1024 * 1024;
const ATTENDANCE_MAX_FILE_SIZE = 20 * 1024 * 1024;

const uploadPhotos = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: REGISTER_MAX_FILE_SIZE },
});

const uploadClassroom = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: ATTENDANCE_MAX_FILE_SIZE },
});

// Python service timeout: 90 seconds (RetinaFace inference can be slow on CPU)
const PYTHON_TIMEOUT_MS = 90_000;


// ------------------------------------------------------------------
// POST /api/student/register
// ------------------------------------------------------------------

app.post(
  "/api/student/register",
  uploadPhotos.array("photos", 3),

  async (req, res) => {
    const connection = await db.getConnection();

    try {
      const { name, rollNo } = req.body;
      const photos = req.files;

      // -----------------------------
      // VALIDATION
      // -----------------------------

      if (!name || !rollNo || !photos || photos.length !== 3) {
        connection.release();
        return res.status(400).json({
          success: false,
          message: "Name, roll number and 3 photos are required",
        });
      }

      console.log("Name:", name);
      console.log("Roll No:", rollNo);
      console.log("Photos:", photos.length);

      // -----------------------------
      // SEND DATA TO PYTHON
      // -----------------------------

      const form = new FormData();

      form.append("student_id", rollNo);

      // Python expects photo1, photo2, photo3 as separate fields
      form.append("photo1", photos[0].buffer, {
        filename: photos[0].originalname || "photo1.jpg",
        contentType: photos[0].mimetype,
      });
      form.append("photo2", photos[1].buffer, {
        filename: photos[1].originalname || "photo2.jpg",
        contentType: photos[1].mimetype,
      });
      form.append("photo3", photos[2].buffer, {
        filename: photos[2].originalname || "photo3.jpg",
        contentType: photos[2].mimetype,
      });

      const pythonResponse = await axios.post(
        "http://127.0.0.1:5000/train",
        form,
        {
          headers: { ...form.getHeaders() },
          timeout: PYTHON_TIMEOUT_MS,
        }
      );

      const pythonData = pythonResponse.data;

      console.log("Python response:", pythonData);

      // -----------------------------
      // VALIDATE PYTHON RESULT
      // -----------------------------

      if (!pythonData.success) {
        connection.release();
        return res.status(400).json({
          success: false,
          message:
            pythonData.message ||
            "Face detection failed. Make sure all 3 photos have a clearly visible face.",
        });
      }

      const embeddings = pythonData.embeddings;

      if (!embeddings || embeddings.length !== 3) {
        connection.release();
        return res.status(400).json({
          success: false,
          message:
            pythonData.message ||
            "Face detection failed. Make sure all 3 photos have a clearly visible face.",
        });
      }

      // -----------------------------
      // TRANSACTION: save student + embeddings atomically
      // -----------------------------

      await connection.beginTransaction();

      const [studentResult] = await connection.execute(
        `INSERT INTO students (name, roll_no) VALUES (?, ?)`,
        [name, rollNo]
      );

      const studentId = studentResult.insertId;

      console.log("Student ID:", studentId);

      for (let i = 0; i < embeddings.length; i++) {
        await connection.execute(
          `INSERT INTO face_embeddings (student_id, photo_number, embedding)
           VALUES (?, ?, ?)`,
          [studentId, i + 1, JSON.stringify(embeddings[i])]
        );
      }

      await connection.commit();
      connection.release();

      console.log("Embeddings saved successfully");

      // -----------------------------
      // SEND RESPONSE
      // -----------------------------

      res.status(201).json({
        success: true,
        message: "Student registered successfully",
        student: {
          id: studentId,
          name: name,
          rollNo: rollNo,
        },
        embeddingsSaved: embeddings.length,
      });
    } catch (error) {
      // Roll back if transaction was started
      try {
        await connection.rollback();
      } catch (_) {
        // ignore rollback error
      }
      connection.release();

      console.error("Registration error:", error.message);

      // Detect duplicate roll number (MySQL error 1062)
      if (error.code === "ER_DUP_ENTRY") {
        return res.status(409).json({
          success: false,
          message: "A student with this roll number is already registered.",
        });
      }

      // Detect Python service timeout
      if (error.code === "ECONNABORTED" || error.code === "ECONNREFUSED") {
        return res.status(503).json({
          success: false,
          message: "Face processing service is unavailable. Please try again.",
        });
      }

      res.status(500).json({
        success: false,
        message: "Student registration failed. Please try again.",
      });
    }
  }
);


// ------------------------------------------------------------------
// POST /api/attendance/take
// ------------------------------------------------------------------

app.post(
  "/api/attendance/take",
  uploadClassroom.single("photo"),
  async (req, res) => {
    try {
      const photo = req.file;

      if (!photo) {
        return res.status(400).json({
          success: false,
          message: "Classroom photo is required",
        });
      }

      console.log("Attendance photo received:");
      console.log("Name:", photo.originalname);
      console.log("Type:", photo.mimetype);
      console.log("Size:", photo.size);

      // -----------------------------
      // Send photo to Python
      // -----------------------------

      const form = new FormData();

      form.append("classroom_photo", photo.buffer, {
        filename: photo.originalname || "classroom.jpg",
        contentType: photo.mimetype,
      });

      const pythonResponse = await axios.post(
        "http://127.0.0.1:5000/recognize",
        form,
        {
          headers: { ...form.getHeaders() },
          timeout: PYTHON_TIMEOUT_MS,
        }
      );

      // -----------------------------
      // Validate Python response before touching the DB
      // -----------------------------

      const pythonData = pythonResponse.data;

      console.log("Python result:", pythonData);

      if (!pythonData.success || !Array.isArray(pythonData.present_students)) {
        return res.status(422).json({
          success: false,
          message:
            pythonData.message ||
            "Face recognition failed. Please retake the photo.",
        });
      }

      // -----------------------------
      // Save attendance to DB
      // -----------------------------

      // Get all registered students
      const [allStudents] = await db.execute("SELECT id FROM students");

      if (allStudents.length === 0) {
        return res.status(400).json({
          success: false,
          message: "No students are registered yet.",
        });
      }

      // Build a set of present student IDs (Python returns DB integer IDs)
      const presentIds = new Set(
        pythonData.present_students.map((s) => Number(s.student_id))
      );

      // Write Present / Absent for every student (idempotent via ON DUPLICATE KEY)
      for (const student of allStudents) {
        const status = presentIds.has(student.id) ? "Present" : "Absent";

        await db.execute(
          `INSERT INTO attendance (student_id, attendance_date, status)
           VALUES (?, CURDATE(), ?)
           ON DUPLICATE KEY UPDATE status = VALUES(status)`,
          [student.id, status]
        );
      }

      console.log("Attendance saved to DB");

      // -----------------------------
      // Send result to frontend
      // -----------------------------

      res.json({
        success: true,
        message: "Attendance processed successfully",
        result: pythonData,
      });
    } catch (error) {
      console.error("Attendance error:", error.message);

      // Python service timeout or unreachable
      if (error.code === "ECONNABORTED" || error.code === "ECONNREFUSED") {
        return res.status(503).json({
          success: false,
          message: "Face processing service is unavailable. Please try again.",
        });
      }

      res.status(500).json({
        success: false,
        message: "Attendance processing failed. Please try again.",
      });
    }
  }
);


// ------------------------------------------------------------------
// GET /api/attendance?date=YYYY-MM-DD
// ------------------------------------------------------------------

app.get("/api/attendance", async (req, res) => {
  try {
    const { date } = req.query;

    if (!date) {
      return res.status(400).json({
        success: false,
        message: "Date is required",
      });
    }

    // Validate format and that it is a real calendar date
    const dateRegex = /^\d{4}-\d{2}-\d{2}$/;
    if (!dateRegex.test(date)) {
      return res.status(400).json({
        success: false,
        message: "Invalid date format. Use YYYY-MM-DD.",
      });
    }

    const parsed = new Date(date);
    if (isNaN(parsed.getTime())) {
      return res.status(400).json({
        success: false,
        message: "Invalid date. Please provide a real calendar date.",
      });
    }

    // Get all students and their attendance status for the given date
    const [rows] = await db.execute(
      `SELECT s.name, s.roll_no,
        COALESCE(a.status, 'Absent') AS status
       FROM students s
       LEFT JOIN attendance a
         ON s.id = a.student_id AND a.attendance_date = ?
       ORDER BY s.roll_no`,
      [date]
    );

    res.json({
      success: true,
      date: date,
      attendance: rows,
    });
  } catch (error) {
    console.error("Fetch attendance error:", error.message);
    res.status(500).json({
      success: false,
      message: "Failed to fetch attendance",
    });
  }
});


app.listen(PORT, () => {
  console.log(`Express running on http://localhost:${PORT}`);
});
