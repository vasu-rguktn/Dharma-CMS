from fastapi import APIRouter, UploadFile, File, HTTPException, Form
from fastapi.responses import JSONResponse
from pydantic import BaseModel, Field
from typing import Optional, Set
from loguru import logger
import traceback

from services.video_enhance_service import enhance_video

router = APIRouter(prefix="/api/video-enhancement", tags=["Video Enhancement"])

# Supported file types
SUPPORTED_MIME_TYPES: Set[str] = {
    "video/mp4", "video/mpeg", "video/quicktime", "video/x-msvideo",
    "video/x-matroska", "video/webm"
}
MAX_FILE_SIZE = 500 * 1024 * 1024  # 500 MB


class VideoEnhancementResponse(BaseModel):
    """Response model for video enhancement"""
    status: str
    output_path: Optional[str] = None
    original_resolution: Optional[str] = None
    final_resolution: Optional[str] = None
    original_fps: Optional[float] = None
    final_fps: Optional[float] = None
    frame_count: Optional[int] = None
    enhancements_applied: Optional[list] = None
    message: Optional[str] = None


def _guess_mime_type(filename: str) -> str:
    """Guess MIME type from filename"""
    ext = filename.lower().split(".")[-1]
    return {
        "mp4": "video/mp4",
        "mpeg": "video/mpeg",
        "mpg": "video/mpeg",
        "mov": "video/quicktime",
        "avi": "video/x-msvideo",
        "mkv": "video/x-matroska",
        "webm": "video/webm",
    }.get(ext, "application/octet-stream")


@router.post("/enhance", response_model=VideoEnhancementResponse)
async def enhance_video_endpoint(
    file: UploadFile = File(..., description="Video file to enhance"),
    denoise: bool = Form(False, description="Enable denoising"),
    deblur: bool = Form(False, description="Enable deblurring"),
    upscale: bool = Form(False, description="Enable upscaling"),
    sharpen: bool = Form(False, description="Enable sharpening"),
    low_light: bool = Form(False, description="Enable low-light enhancement"),
    stabilize: bool = Form(False, description="Enable temporal stabilization"),
    contrast: bool = Form(False, description="Enable contrast enhancement"),
    denoise_strength: int = Form(10, ge=1, le=30, description="Denoising strength (1-30)"),
    deblur_kernel_size: int = Form(15, ge=3, le=31, description="Deblur kernel size (odd number, 3-31)"),
    upscale_factor: float = Form(2.0, ge=1.1, le=4.0, description="Upscale factor (1.1-4.0)"),
    upscale_preset: Optional[str] = Form(None, description="Resolution preset: '360p', '480p', '720p', '1080p', '2k', '4k' (overrides upscale_factor)"),
    upscale_method: str = Form("cubic", description="Upscale method: 'cubic', 'lanczos', 'linear', 'nearest'"),
    sharpen_strength: float = Form(1.0, ge=0.1, le=3.0, description="Sharpening strength (0.1-3.0)"),
    low_light_gamma: float = Form(1.2, ge=0.5, le=2.0, description="Gamma correction for low-light (0.5-2.0)"),
    contrast_factor: float = Form(1.2, ge=1.0, le=3.0, description="Contrast factor (1.0-3.0)"),
    output_format: str = Form("mp4", description="Output format: 'mp4', 'avi', 'mov'"),
    output_quality: int = Form(23, ge=0, le=51, description="Output quality (0-51, lower = better)"),
    maintain_fps: bool = Form(True, description="Maintain original FPS")
):
    """
    Enhance video with selected operations.
    
    You can select any combination of:
    - Denoise: Remove noise from video frames
    - Deblur: Reduce blur and sharpen edges
    - Upscale: Increase video resolution (super resolution)
      - Use upscale_factor for custom scaling (e.g., 2.0 = 2x)
      - Use upscale_preset for standard resolutions (e.g., '2k' = 2560x1440)
    - Sharpen: Sharpen video details
    - Low-light: Boost brightness and contrast for dark videos
    - Stabilize: Apply temporal stabilization to reduce jitter
    - Contrast: Enhance contrast
    
    Operations are applied in optimal order for best results.
    
    Examples:
    - Convert 360p to 2K: upscale=True, upscale_preset='2k'
    - Convert 480p to 1080p: upscale=True, upscale_preset='1080p'
    - Upscale 2x: upscale=True, upscale_factor=2.0
    """
    # Validate file
    if not file.filename:
        raise HTTPException(status_code=400, detail="No file uploaded")
    
    content_type = file.content_type or _guess_mime_type(file.filename)
    if content_type not in SUPPORTED_MIME_TYPES:
        raise HTTPException(
            status_code=400,
            detail=f"Unsupported file type: {content_type}. Supported types: MP4, AVI, MOV, MKV, WebM"
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
    enhancements = [denoise, deblur, upscale, sharpen, low_light, stabilize, contrast]
    if not any(enhancements):
        raise HTTPException(
            status_code=400,
            detail="At least one enhancement option must be selected"
        )
    
    # Validate upscale_preset if provided
    if upscale_preset:
        valid_presets = ["360p", "480p", "720p", "1080p", "2k", "4k"]
        if upscale_preset.lower() not in valid_presets:
            raise HTTPException(
                status_code=400,
                detail=f"Invalid upscale_preset: {upscale_preset}. Valid options: {valid_presets}"
            )
    
    # Validate upscale_method
    valid_methods = ["cubic", "lanczos", "linear", "nearest"]
    if upscale_method.lower() not in valid_methods:
        raise HTTPException(
            status_code=400,
            detail=f"Invalid upscale_method: {upscale_method}. Valid options: {valid_methods}"
        )
    
    # Validate output_format
    valid_formats = ["mp4", "avi", "mov"]
    if output_format.lower() not in valid_formats:
        raise HTTPException(
            status_code=400,
            detail=f"Invalid output_format: {output_format}. Valid options: {valid_formats}"
        )
    
    # Ensure deblur_kernel_size is odd
    if deblur_kernel_size % 2 == 0:
        deblur_kernel_size += 1
    
    try:
        logger.info(
            f"Video enhancement request: "
            f"denoise={denoise}, deblur={deblur}, upscale={upscale}, "
            f"sharpen={sharpen}, low_light={low_light}, stabilize={stabilize}, "
            f"contrast={contrast}, file_size={len(contents)} bytes"
        )
        
        # Create a file-like object from bytes for the service
        from io import BytesIO
        file_obj = BytesIO(contents)
        file_obj.name = file.filename
        
        # Pass file object to the service
        result = enhance_video(
            file=file_obj,
            denoise_enabled=denoise,
            deblur_enabled=deblur,
            upscale_enabled=upscale,
            sharpen_enabled=sharpen,
            low_light_enabled=low_light,
            stabilize_enabled=stabilize,
            contrast_enabled=contrast,
            denoise_strength=denoise_strength,
            deblur_kernel_size=deblur_kernel_size,
            upscale_factor=upscale_factor,
            upscale_preset=upscale_preset.lower() if upscale_preset else None,
            upscale_method=upscale_method.lower(),
            sharpen_strength=sharpen_strength,
            low_light_gamma=low_light_gamma,
            contrast_factor=contrast_factor,
            output_format=output_format.lower(),
            output_quality=output_quality,
            maintain_fps=maintain_fps
        )
        
        return VideoEnhancementResponse(**result)
        
    except ValueError as e:
        logger.error(f"ValueError in video enhancement: {str(e)}")
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        logger.error(f"Unexpected error in video enhancement: {str(e)}")
        logger.error(traceback.format_exc())
        raise HTTPException(status_code=500, detail=f"Video enhancement failed: {str(e)}")


@router.get("/health")
async def health_check():
    """Health check endpoint"""
    return {"status": "ok", "service": "video-enhancement"}


@router.get("/presets")
async def get_presets():
    """Get available resolution presets"""
    return {
        "presets": {
            "360p": {"width": 640, "height": 360},
            "480p": {"width": 854, "height": 480},
            "720p": {"width": 1280, "height": 720},
            "1080p": {"width": 1920, "height": 1080},
            "2k": {"width": 2560, "height": 1440},
            "4k": {"width": 3840, "height": 2160},
        },
        "upscale_methods": ["cubic", "lanczos", "linear", "nearest"],
        "output_formats": ["mp4", "avi", "mov"]
    }
