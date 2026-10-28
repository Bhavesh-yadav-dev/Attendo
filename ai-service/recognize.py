import os
import json
import shutil
import tempfile
import numpy as np
from deepface import DeepFace
from db import get_connection

# Threshold - if distance is less than this, face is a match
DISTANCE_THRESHOLD = 0.33

# Minimum confidence to consider a detected face valid
FACE_CONFIDENCE_THRESHOLD = 0.40


def cosine_distance(v1, v2):
    # Calculate how similar two face embeddings are
    # Lower value = more similar
    v1 = np.array(v1)
    v2 = np.array(v2)

    denominator = np.linalg.norm(v1) * np.linalg.norm(v2)

    if denominator == 0:
        return float("inf")

    return 1 - (np.dot(v1, v2) / denominator)


def load_embeddings_from_db():
    """
    Fetch all student embeddings from the database.
    Returns a list like:
    [
        {
            "student_id": 1,
            "name": "Rahul",
            "roll_no": "101",
            "embeddings": [[...512...], [...512...], [...512...]]
        },
        ...
    ]
    """
    connection = get_connection()
    cursor = connection.cursor(dictionary=True)

    try:
        # Get all students
        cursor.execute("SELECT id, name, roll_no FROM students")
        students = cursor.fetchall()

        student_data = []

        for student in students:
            # Get all embeddings for this student
            cursor.execute(
                "SELECT embedding FROM face_embeddings WHERE student_id = %s ORDER BY photo_number",
                (student["id"],)
            )
            rows = cursor.fetchall()

            embeddings = []
            for row in rows:
                # embedding is stored as JSON string in DB, parse it
                embedding = json.loads(row["embedding"])

                # Safety check - only use valid 512-dimension embeddings
                if isinstance(embedding, list) and len(embedding) == 512:
                    embeddings.append(embedding)
                else:
                    print(f"[SKIP] Bad embedding for student {student['id']} - length: {len(embedding) if isinstance(embedding, list) else 'not a list'}")

            student_data.append({
                "student_id": student["id"],
                "name": student["name"],
                "roll_no": student["roll_no"],
                "embeddings": embeddings
            })

    finally:
        # Always close connection even if error occurs
        cursor.close()
        connection.close()

    return student_data


def recognize_students(image_bytes: bytes):
    """
    Receives classroom photo as bytes.
    Detects all faces, matches them against DB embeddings.
    Returns list of present students.
    """

    # Use a unique temp folder per request to avoid race conditions
    temp_folder = tempfile.mkdtemp(prefix="recognize_")

    image_path = os.path.join(temp_folder, "classroom.jpg")
    with open(image_path, "wb") as f:
        f.write(image_bytes)

    # Load all student embeddings from DB
    all_students = load_embeddings_from_db()

    if len(all_students) == 0:
        shutil.rmtree(temp_folder, ignore_errors=True)
        return {
            "success": False,
            "message": "No student data found in database.",
            "present_students": []
        }

    # Detect all faces in the classroom image
    try:
        detected_faces = DeepFace.represent(
            img_path=image_path,
            model_name="Facenet512",
            detector_backend="retinaface",
            enforce_detection=False
        )
    except Exception as e:
        shutil.rmtree(temp_folder, ignore_errors=True)
        return {
            "success": False,
            "message": f"Face detection failed: {str(e)}",
            "present_students": []
        }

    present_students = []
    already_added = set()  # avoid adding same student twice

    # Loop through each detected face
    for face in detected_faces:

        # Skip low confidence detections
        if face.get("face_confidence", 0) < FACE_CONFIDENCE_THRESHOLD:
            continue

        query_embedding = face["embedding"]

        best_match_name = None
        best_match_roll = None
        best_match_id = None
        best_distance = float("inf")

        # Compare this face against every student's embeddings
        for student in all_students:
            for saved_embedding in student["embeddings"]:
                distance = cosine_distance(query_embedding, saved_embedding)

                if distance < best_distance:
                    best_distance = distance
                    best_match_name = student["name"]
                    best_match_roll = student["roll_no"]
                    best_match_id = student["student_id"]

        # If best match is within threshold, mark as present
        if best_match_id is not None and best_distance <= DISTANCE_THRESHOLD:
            if best_match_id not in already_added:
                already_added.add(best_match_id)
                present_students.append({
                    "student_id": best_match_id,
                    "name": best_match_name,
                    "roll_no": best_match_roll
                })
                print(f"[PRESENT] {best_match_name} ({best_match_roll}) - distance: {best_distance:.3f}")
        else:
            print(f"[UNKNOWN] distance: {best_distance:.3f}")

    # Clean up unique temp folder
    shutil.rmtree(temp_folder, ignore_errors=True)

    return {
        "success": True,
        "message": "Recognition completed.",
        "total_faces_detected": len(detected_faces),
        "total_present": len(present_students),
        "present_students": present_students
    }
