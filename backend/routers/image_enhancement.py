from fastapi import APIRouter, UploadFile, File
from services.image_enhance_service import enhance_image

router = APIRouter(prefix="/image", tags=["Image Enhancement"])

@router.post("/enhance")
async def image_enhance(
    file: UploadFile = File(...),
    denoise: bool = False,
    deblur: bool = False,
    low_light: bool = False,
    upscale: bool = False
):
    return enhance_image(file, denoise, deblur, low_light, upscale)
