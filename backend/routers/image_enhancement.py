from fastapi import APIRouter, UploadFile, File, HTTPException, Form
from fastapi.responses import JSONResponse
from pydantic import BaseModel, Field
from typing import Optional, Set
from loguru import logger
import traceback

from services.image_enhance_service import enhance_image

router = APIRouter(prefix="/api/image-enhancement", tags=["Image Enhancement"])

# Supported file types
SUPPORTED_MIME_TYPES: Set[str] = {"image/jpeg", "image/jpg", "image/png", "image/webp"}
MAX_FILE_SIZE = 10 * 1024 * 1024  # 10 MB


class ImageEnhancementResponse(BaseModel):
    """Response model for image enhancement"""
    status: str
    output_path: Optional[str] = None
    image_base64: Optional[str] = None
    original_shape: Optional[list] = None
    final_shape: Optional[list] = None
    message: Optional[str] = None


def _guess_mime_type(filename: str) -> str:
    """Guess MIME type from filename"""
    ext = filename.lower().split(".")[-1]
    return {
        "jpg": "image/jpeg",
        "jpeg": "image/jpeg",
        "png": "image/png",
        "webp": "image/webp",
    }.get(ext, "application/octet-stream")


@router.post("/enhance", response_model=ImageEnhancementResponse)
async def enhance_image_endpoint(
    file: UploadFile = File(..., description="Image file to enhance"),
    denoise: bool = Form(False, description="Enable denoising"),
    deblur: bool = Form(False, description="Enable deblurring"),
    colorize: bool = Form(False, description="Enable colorization/saturation enhancement"),
    sharpen: bool = Form(False, description="Enable sharpening"),
    low_light: bool = Form(False, description="Enable low-light enhancement"),
    upscale: bool = Form(False, description="Enable upscaling"),
    denoise_strength: int = Form(10, ge=1, le=30, description="Denoising strength (1-30)"),
    deblur_kernel_size: int = Form(15, ge=3, le=31, description="Deblur kernel size (odd number, 3-31)"),
    colorize_saturation: float = Form(1.5, ge=0.1, le=3.0, description="Saturation factor (0.1-3.0)"),
    sharpen_strength: float = Form(1.0, ge=0.1, le=3.0, description="Sharpening strength (0.1-3.0)"),
    low_light_gamma: float = Form(1.2, ge=0.5, le=2.0, description="Gamma correction for low-light (0.5-2.0)"),
    upscale_factor: float = Form(2.0, ge=1.1, le=4.0, description="Upscale factor (1.1-4.0)"),
    return_base64: bool = Form(False, description="Return base64 encoded image instead of file path")
):
    """
    Enhance image with selected operations.
    
    You can select any combination of:
    - Denoise: Remove noise from image
    - Deblur: Reduce blur and sharpen edges
    - Colorize: Enhance saturation and colors
    - Sharpen: Sharpen image details
    - Low-light: Boost brightness and contrast for dark images
    - Upscale: Increase image resolution
    
    Operations are applied in optimal order for best results.
    """
    # Validate file
    if not file.filename:
        raise HTTPException(status_code=400, detail="No file uploaded")
    
    content_type = file.content_type or _guess_mime_type(file.filename)
    if content_type not in SUPPORTED_MIME_TYPES:
        raise HTTPException(
            status_code=400,
            detail=f"Unsupported file type: {content_type}. Supported types: JPEG, PNG, WebP"
        )
    
    # Read and validate file size
    try:
        contents = await file.read(MAX_FILE_SIZE + 1)
    except Exception as e:
        logger.error(f"Error reading file: {str(e)}")
        raise HTTPException(status_code=400, detail="Failed to read file")
    
    if len(contents) > MAX_FILE_SIZE:
        raise HTTPException(status_code=400, detail=f"File too large (max {MAX_FILE_SIZE / 1024 / 1024}MB)")
    
    if len(contents) == 0:
        raise HTTPException(status_code=400, detail="Empty file")
    
    # Check if at least one enhancement is selected
    enhancements = [denoise, deblur, colorize, sharpen, low_light, upscale]
    if not any(enhancements):
        raise HTTPException(
            status_code=400,
            detail="At least one enhancement option must be selected"
        )
    
    # Ensure deblur_kernel_size is odd
    if deblur_kernel_size % 2 == 0:
        deblur_kernel_size += 1
    
    try:
        # Read file contents once (already read above)
        logger.info(
            f"Image enhancement request: "
            f"denoise={denoise}, deblur={deblur}, colorize={colorize}, "
            f"sharpen={sharpen}, low_light={low_light}, upscale={upscale}, "
            f"file_size={len(contents)} bytes"
        )
        
        # Pass bytes directly to the service
        result = enhance_image(
            file=contents,  # Pass bytes directly
            denoise_enabled=denoise,
            deblur_enabled=deblur,
            colorize_enabled=colorize,
            sharpen_enabled=sharpen,
            low_light_enabled=low_light,
            upscale_enabled=upscale,
            denoise_strength=denoise_strength,
            deblur_kernel_size=deblur_kernel_size,
            colorize_saturation=colorize_saturation,
            sharpen_strength=sharpen_strength,
            low_light_gamma=low_light_gamma,
            upscale_factor=upscale_factor,
            return_base64=return_base64
        )
        
        return ImageEnhancementResponse(**result)
        
    except ValueError as e:
        logger.error(f"ValueError in image enhancement: {str(e)}")
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        logger.error(f"Unexpected error in image enhancement: {str(e)}")
        logger.error(traceback.format_exc())
        raise HTTPException(status_code=500, detail=f"Image enhancement failed: {str(e)}")


@router.get("/health")
async def health_check():
    """Health check endpoint"""
    return {"status": "ok", "service": "image-enhancement"}
