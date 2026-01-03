from fastapi import APIRouter, UploadFile, File, Form, HTTPException
from fastapi.responses import FileResponse
import cv2
import numpy as np
from pathlib import Path
from loguru import logger
from services.image_lab.person_service import (
    detect_persons_image,
    detect_persons_video,
    create_persons_zip
)

router = APIRouter(prefix="/api/person", tags=["Person Detection"])

@router.post("/detect")
async def detect_person(
    file: UploadFile = File(...),
    is_video: bool = Form(False),
    frame_skip: int = Form(10)
):
    logger.info(f"Received detection request: filename={file.filename}, is_video={is_video}, frame_skip={frame_skip}")
    try:
        contents = await file.read()
        logger.debug(f"File read successfully, size: {len(contents)} bytes")

        if is_video:
            # Ensure temp_videos directory exists
            Path("temp_videos").mkdir(exist_ok=True)
            temp_path = Path("temp_videos") / file.filename
            
            logger.debug(f"Saving video to temp path: {temp_path}")
            with open(temp_path, "wb") as f:
                f.write(contents)
            
            logger.info("Starting video detection service...")
            result = detect_persons_video(str(temp_path), frame_skip)
            logger.success("Video detection completed successfully")
            return {"status": "success", **result}

        # IMAGE PATH
        logger.debug("Decoding image...")
        img_array = np.frombuffer(contents, np.uint8)
        image = cv2.imdecode(img_array, cv2.IMREAD_COLOR)

        if image is None:
            logger.error("Failed to decode image - result is None")
            return {"status": "error", "message": "Invalid image"}

        logger.info("Starting image detection service...")
        result = detect_persons_image(image)
        logger.success(f"Image detection completed: {result}")
        return {"status": "success", **result}
        
    except Exception as e:
        logger.exception("Error in detect_person endpoint")
        raise HTTPException(status_code=500, detail=f"Internal Server Error: {str(e)}")

@router.get("/download/{session_id}")
async def download_persons(session_id: str):
    logger.info(f"Received download request for session: {session_id}")
    try:
        zip_path = create_persons_zip(session_id)
        logger.debug(f"Zip created at: {zip_path}")
        return FileResponse(
            zip_path,
            media_type='application/zip',
            filename=f"persons_{session_id}.zip"
        )
    except ValueError as e:
        logger.warning(f"Session not found: {session_id}")
        raise HTTPException(status_code=404, detail="Session not found")
    except Exception as e:
        logger.exception("Error in download_persons endpoint")
        raise HTTPException(status_code=500, detail=str(e))
