import os
import shutil
import tempfile
from deepface import DeepFace

def generate_embeddings(student_id: str, images: list):
    """
    Receives 3 images as bytes, generates face embeddings for each,
    and returns them as a list.

    student_id : roll number or ID of the student
    images     : list of 3 image byte arrays
    """

    # Use a unique temp folder per request to avoid race conditions
    temp_folder = tempfile.mkdtemp(prefix="train_")

    saved_paths = []

    try:
        # Save each uploaded image to the unique temp folder
        for i, image in enumerate(images):
            image_path = os.path.join(temp_folder, f"photo_{i+1}.jpg")
            with open(image_path, "wb") as f:
                f.write(image)
            saved_paths.append(image_path)

        embeddings = []
        failed_photos = []

        # Generate embedding for each saved image
        for i, image_path in enumerate(saved_paths):
            try:
                result = DeepFace.represent(
                    img_path=image_path,
                    model_name="Facenet512",
                    detector_backend="retinaface",
                    enforce_detection=True   # raises ValueError if no face detected
                )

                # Reject photos containing more than one face
                if len(result) > 1:
                    failed_photos.append(i + 1)
                    print(f"[FAILED] photo_{i+1} - multiple faces detected ({len(result)})")
                    continue

                # embedding is a list of 512 numbers
                embedding = result[0]["embedding"]
                embeddings.append(embedding)
                print(f"[OK] Embedding generated for photo {i+1}")

            except Exception as e:
                failed_photos.append(i + 1)
                print(f"[FAILED] photo_{i+1} - {type(e).__name__}")

    finally:
        # Always clean up temp folder
        shutil.rmtree(temp_folder, ignore_errors=True)

    # If no embeddings were generated, return failure with detail
    if len(embeddings) == 0:
        return {
            "success": False,
            "message": f"No valid face found in any of the photos (failed: {failed_photos}). Please retake clearer photos.",
            "student_id": student_id,
            "embeddings": []
        }

    # If some but not all embeddings succeeded
    if len(embeddings) < 3:
        return {
            "success": False,
            "message": f"Could not detect a face in photo(s) {failed_photos}. All 3 photos must have a clearly visible face.",
            "student_id": student_id,
            "embeddings": []
        }

    return {
        "success": True,
        "message": "Embeddings generated successfully.",
        "student_id": student_id,
        "embeddings": embeddings  # list of 3 embeddings (each is 512 numbers)
    }
