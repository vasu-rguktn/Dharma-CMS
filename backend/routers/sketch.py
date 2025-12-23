# backend/routes/sketch.py

from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from services.sketch_service import generate_sketch

router = APIRouter(prefix="/api/sketch", tags=["Sketch Generation"])


class SketchRequest(BaseModel):
    prompt: str


@router.post("/generate")
def generate_sketch_route(data: SketchRequest):
    try:
        result = generate_sketch(data.prompt)
        return {
            "status": "success",
            "image_base64": result["image_base64"]
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
