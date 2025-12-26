from fastapi import APIRouter, UploadFile, File, Form, HTTPException
from fastapi.responses import JSONResponse
from pydantic import BaseModel
from typing import Optional, Set, Any, Dict
from loguru import logger
import traceback
import numpy as np

from services.anpr_service import detect_plate

router = APIRouter(prefix="/api/anpr", tags=["ANPR"])

# Supported file types
SUPPORTED_IMAGE_TYPES: Set[str] = {"image/jpeg", "image/jpg", "image/png", "image/webp", "image/jfif"}
SUPPORTED_VIDEO_TYPES: Set[str] = {
    "video/mp4", "video/mpeg", "video/quicktime", "video/x-msvideo",
    "video/x-matroska", "video/webm"
}
MAX_FILE_SIZE = 500 * 1024 * 1024  # 500 MB


class ANPRResponse(BaseModel):
    """Response model for ANPR detection"""
    status: str
    plates: Optional[list] = None
    count: Optional[int] = None
    type: Optional[str] = None
    total_frames: Optional[int] = None
    processed_frames: Optional[int] = None
    frames_with_plates: Optional[int] = None
    unique_plates: Optional[list] = None
    all_detections: Optional[list] = None
    message: Optional[str] = None
    image: Optional[str] = None
    video_url: Optional[str] = None


def _make_json_serializable(obj: Any) -> Any:
    """Convert numpy types and other non-serializable objects to JSON-compatible types"""
    if isinstance(obj, (np.integer, np.floating)):
        return obj.item()
    elif isinstance(obj, np.ndarray):
        return obj.tolist()
    elif isinstance(obj, dict):
        return {k: _make_json_serializable(v) for k, v in obj.items()}
    elif isinstance(obj, (list, tuple)):
        return [_make_json_serializable(item) for item in obj]
    elif hasattr(obj, '__dict__'):
        try:
            return vars(obj)
        except TypeError:
            return str(obj)
    return obj


def _guess_mime_type(filename: str) -> str:
    """Guess MIME type from filename"""
    ext = filename.lower().split(".")[-1]
    image_exts = {"jpg", "jpeg", "png", "webp","jfif"}
    video_exts = {"mp4", "mpeg", "mpg", "mov", "avi", "mkv", "webm"}
    
    if ext in image_exts:
        return f"image/{ext if ext != 'jpg' else 'jpeg'}"
    elif ext in video_exts:
        return f"video/{ext if ext != 'mpeg' else 'mp4'}"
    else:
        return "application/octet-stream"


@router.post("/detect", response_model=ANPRResponse)
async def anpr_detect(
    file: UploadFile = File(..., description="Image or video file"),
    frame_skip: int = Form(10, ge=1, le=30, description="For videos: number of frames to skip (default: 10)")
):
    """
    Detect and read vehicle number plates from an image or video.
    
    For videos:
    - Processes every Nth frame (default: every 10th frame) for faster processing
    - Returns unique plates found across all frames
    - Includes frame numbers and timestamps for each detection
    
    For images:
    - Processes the entire image
    - Returns all detected plates with bounding boxes and text
    """
    # Validate file
    if not file.filename:
        raise HTTPException(status_code=400, detail="No file uploaded")
    
    content_type = file.content_type or _guess_mime_type(file.filename)
    is_video = content_type in SUPPORTED_VIDEO_TYPES
    
    if not is_video and content_type not in SUPPORTED_IMAGE_TYPES:
        raise HTTPException(
            status_code=400,
            detail=f"Unsupported file type: {content_type}. Supported: Images (JPEG, PNG, WebP) or Videos (MP4, AVI, MOV, MKV, WebM)"
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
    
    try:
        logger.info(
            f"ANPR detection request: file={file.filename}, "
            f"type={'video' if is_video else 'image'}, "
            f"size={len(contents)} bytes"
        )
        
        # Create a file-like object from bytes
        from io import BytesIO
        file_obj = BytesIO(contents)
        file_obj.name = file.filename
        
        # Detect plates
        result = detect_plate(file_obj, is_video=is_video, frame_skip=frame_skip)
        
        # Ensure all values are JSON serializable (convert numpy types)
        result = _make_json_serializable(result)
        
        # Add success message
        if is_video:
            result["message"] = f"Detected {len(result.get('unique_plates', []))} unique plate(s) in {result.get('processed_frames', 0)} processed frames"
            if "video_filename" in result:
                 # Construct URL assuming static mount at /static/anpr_videos
                 result["video_url"] = f"/static/anpr_videos/{result['video_filename']}"
                 logger.info(f"Returned video URL: {result['video_url']}")
        else:
            result["message"] = f"Detected {result.get('count', 0)} plate(s)"
        
        return ANPRResponse(**result)
        
    except ValueError as e:
        logger.error(f"ValueError in ANPR detection: {str(e)}")
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        logger.error(f"Unexpected error in ANPR detection: {str(e)}")
        logger.error(traceback.format_exc())
        raise HTTPException(status_code=500, detail=f"ANPR detection failed: {str(e)}")


@router.get("/health")
async def health_check():
    """Health check endpoint"""
    return {"status": "ok", "service": "anpr"}
