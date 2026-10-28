from fastapi import FastAPI, UploadFile, File, Form
from train import generate_embeddings
from recognize import recognize_students
from db import get_connection

# Create the FastAPI app
app = FastAPI()

# Root endpoint
@app.get("/")
def read_root():
    return {
        "message": "Python face processing server is running"
    }

# ---------------------------------------------------------
# ROUTE 0: Test DB Connection
# GET /test-db
# Just to check if database is connected or not
# ---------------------------------------------------------

@app.get("/test-db")
def test_db():
    try:
        connection = get_connection()
        connection.close()
        return {"success": True, "message": "Database connected successfully!"}
    except Exception as e:
        return {"success": False, "message": str(e)}


# ---------------------------------------------------------
# ROUTE 1: Training
# POST /train
#
# Server sends 3 images + student_id
# This service generates embeddings and returns them as JSON
# Server will save the embeddings to the database
# ---------------------------------------------------------

@app.post("/train")
async def train(
    student_id: str = Form(...),
    photo1: UploadFile = File(...),
    photo2: UploadFile = File(...),
    photo3: UploadFile = File(...)
):
    # Read image bytes from uploaded files
    photo1_bytes = await photo1.read()
    photo2_bytes = await photo2.read()
    photo3_bytes = await photo3.read()

    images = [photo1_bytes, photo2_bytes, photo3_bytes]

    # Call train.py to generate embeddings
    result = generate_embeddings(student_id, images)

    return result


# ---------------------------------------------------------
# ROUTE 2: Attendance Recognition
# POST /recognize
#
# Server sends a classroom group photo
# This service fetches embeddings from DB, matches faces,
# and returns the list of present students
# ---------------------------------------------------------

@app.post("/recognize")
async def recognize(
    classroom_photo: UploadFile = File(...)
):
    # Read image bytes from uploaded file
    image_bytes = await classroom_photo.read()

    # Call recognize.py to detect and match faces
    result = recognize_students(image_bytes)

    return result


# ---------------------------------------------------------
# Run the app (only when running this file directly)
# Command: uvicorn main:app --reload
# ---------------------------------------------------------

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="0.0.0.0", port=5000, reload=True)
