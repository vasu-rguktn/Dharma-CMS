from fastapi import APIRouter, UploadFile, File
from services.face_service import detect_faces

router = APIRouter(prefix="/face", tags=["Face Detection"])

@router.post("/detect")
async def face_detect(file: UploadFile = File(...)):
    return detect_faces(file)
