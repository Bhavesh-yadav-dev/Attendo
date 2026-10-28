# Attendo — AI-Powered Face Recognition Attendance System

Attendo is a classroom attendance system that uses face recognition to automatically mark students present or absent. A teacher registers each student with three photos, then takes a single group photo of the classroom to record attendance for the day.

---

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Mobile app | Flutter (Dart) |
| Backend API | Node.js + Express (port 8000) |
| AI service | Python + FastAPI (port 5000) |
| Face recognition | DeepFace — Facenet512 model, RetinaFace detector |
| Database | MySQL |

---

## Project Structure

```
attendo/
├── lib/                        # Flutter app
│   ├── config/
│   │   └── api_config.dart     # Base URL configuration
│   ├── pages/
│   │   ├── dashboard.dart      # Home screen with today's stats
│   │   ├── registar_student.dart  # Student registration screen
│   │   ├── take_attendance.dart   # Classroom photo capture screen
│   │   └── view_attendance.dart   # Attendance history screen
│   ├── services/
│   │   └── student_api_service.dart  # HTTP calls to Express
│   └── main.dart
│
├── server/                     # Node.js + Express backend
│   ├── server.js               # All API routes
│   ├── db.js                   # MySQL connection pool
│   ├── .env                    # DB credentials (not committed)
│   └── package.json
│
├── ai-service/                 # Python FastAPI service
│   ├── main.py                 # FastAPI app and routes
│   ├── train.py                # Face embedding generation
│   ├── recognize.py            # Face recognition logic
│   ├── db.py                   # MySQL connection helper
│   ├── .env                    # DB credentials (not committed)
│   └── requirements.txt
│
└── schema.sql                  # MySQL database schema
```

---

## How It Works

### Student Registration

1. Teacher enters the student's name and roll number, then selects three clear face photos.
2. Flutter sends a multipart POST request to Express `/api/student/register`.
3. Express forwards the three photos to FastAPI `/train`.
4. FastAPI runs DeepFace (Facenet512 + RetinaFace) on each photo and generates a 512-dimensional face embedding.
5. Express saves the student record and all three embeddings to MySQL inside a single transaction.

### Taking Attendance

1. Teacher takes a group photo of the classroom.
2. Flutter sends the photo to Express `/api/attendance/take`.
3. Express forwards it to FastAPI `/recognize`.
4. FastAPI detects all faces in the image, computes embeddings, and compares each face against every stored student embedding using cosine distance.
5. Any face within the recognition threshold is marked Present; all others are marked Absent.
6. Express writes one attendance row per student for today's date (idempotent — repeated requests update the existing record).

### Viewing Attendance

- Teacher selects a date in the app and fetches the attendance list via `GET /api/attendance?date=YYYY-MM-DD`.
- The screen shows each student's name, roll number, and status with a Present/Absent count summary.

---

## Database Schema

Run `schema.sql` once to create all tables:

```bash
mysql -u root -p < schema.sql
```

Tables created:

- **students** — `id`, `name`, `roll_no` (unique)
- **face_embeddings** — `student_id` (FK), `photo_number` (1–3), `embedding` (JSON array of 512 floats)
- **attendance** — `student_id` (FK), `attendance_date`, `status` (Present/Absent); unique per student per date

---

## Setup

### Prerequisites

- Flutter SDK
- Node.js 18+
- Python 3.9+
- MySQL 8+

### 1. Database

```bash
mysql -u root -p < schema.sql
```

### 2. Python AI Service

```bash
cd ai-service

# Create and activate a virtual environment
python -m venv venv
venv\Scripts\activate        # Windows
# source venv/bin/activate   # macOS / Linux

pip install -r requirements.txt

# Create .env with your database credentials
cp .env.example .env         # then edit .env
```

`.env` format:
```
DB_HOST=127.0.0.1
DB_USER=root
DB_PASSWORD=your_password
DB_NAME=attendance_system
```

Start the service:
```bash
uvicorn main:app --host 0.0.0.0 --port 5000 --reload
```

### 3. Node.js Express Server

```bash
cd server

npm install

# Create .env with your database credentials
```

`.env` format:
```
PORT=8000
DB_HOST=127.0.0.1
DB_USER=root
DB_PASSWORD=your_password
DB_NAME=attendance_system
```

Start the server:
```bash
npm run dev
```

### 4. Flutter App

Update the Express server IP in `lib/config/api_config.dart`:

```dart
class ApiConfig {
  // Use 10.0.2.2 for Android emulator, or your machine's LAN IP for a physical device
  static const String baseUrl = 'http://10.0.2.2:8000';
}
```

Run the app:
```bash
flutter pub get
flutter run
```

---

## API Reference

### POST `/api/student/register`
Registers a new student with three face photos.

| Field | Type | Description |
|-------|------|-------------|
| `name` | form field | Student's full name |
| `rollNo` | form field | Unique roll number |
| `photos` | file (×3) | Three face photos |

**Response** `201`:
```json
{
  "success": true,
  "message": "Student registered successfully",
  "student": { "id": 1, "name": "Rahul", "rollNo": "101" },
  "embeddingsSaved": 3
}
```

---

### POST `/api/attendance/take`
Processes a classroom photo and records attendance.

| Field | Type | Description |
|-------|------|-------------|
| `photo` | file | Classroom group photo |

**Response** `200`:
```json
{
  "success": true,
  "message": "Attendance processed successfully",
  "result": {
    "total_faces_detected": 5,
    "total_present": 3,
    "present_students": [
      { "student_id": 1, "name": "Rahul", "roll_no": "101" }
    ]
  }
}
```

---

### GET `/api/attendance?date=YYYY-MM-DD`
Returns attendance records for a specific date.

**Response** `200`:
```json
{
  "success": true,
  "date": "2026-10-28",
  "attendance": [
    { "name": "Rahul", "roll_no": "101", "status": "Present" },
    { "name": "Priya", "roll_no": "102", "status": "Absent" }
  ]
}
```

---

## Configuration Notes

- **Android emulator** — use `http://10.0.2.2:8000` as the base URL (emulator maps this to the host machine's localhost).
- **Physical device** — use your machine's LAN IP address (e.g. `http://192.168.1.5:8000`). Both the device and the machine must be on the same Wi-Fi network.
- **Recognition threshold** — controlled by `DISTANCE_THRESHOLD = 0.33` in `ai-service/recognize.py`. Lower values are stricter; adjust based on empirical testing with your dataset.
- **First inference** — DeepFace downloads model weights on first use (~250 MB). Subsequent calls are faster.

---

## Security Notes

- Never commit `.env` files. Both `server/.env` and `ai-service/.env` are listed in `.gitignore`.
- There is currently no authentication on the API endpoints. Add token-based auth before any school-wide deployment.
- Face embeddings are biometric data. Ensure appropriate consent is obtained before registering students.
