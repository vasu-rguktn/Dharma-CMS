from fastapi import APIRouter
from services.sketch_service import generate_sketch

router = APIRouter(prefix="/sketch", tags=["Sketch Generation"])

@router.post("/generate")
async def sketch_from_text(prompt: str):
    return generate_sketch(prompt)
