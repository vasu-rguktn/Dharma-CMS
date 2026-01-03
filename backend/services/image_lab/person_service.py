import cv2
import numpy as np
from ultralytics import YOLO
from pathlib import Path
from loguru import logger
from utils.person_utils import compute_image_hash
import uuid
import shutil



BASE_DIR = Path(__file__).resolve().parents[2]
STORAGE_DIR = BASE_DIR / "storage" / "persons"
TEMP_VIDEO_DIR = BASE_DIR / "temp_videos"

STORAGE_DIR.mkdir(parents=True, exist_ok=True)
TEMP_VIDEO_DIR.mkdir(parents=True, exist_ok=True)
try:
    # Use custom face detector model
    MODEL_PATH = BASE_DIR / "models" / "face_detector.pt"
    if MODEL_PATH.exists():
        model = YOLO(str(MODEL_PATH))
        logger.success(f"Loaded custom model: {MODEL_PATH}")
    else:
        logger.warning(f"Custom model not found at {MODEL_PATH}, falling back to yolov8n.pt")
        model = YOLO("yolov8n.pt")
        
except Exception:
    logger.error("Failed to load YOLOv8 model", exc_info=True)
    model = None



def detect_persons_image(image: np.ndarray):
    if model is None:
        raise ValueError("YOLOv8 model not loaded")

    session_id = str(uuid.uuid4())
    session_dir = STORAGE_DIR / session_id
    session_dir.mkdir(parents=True, exist_ok=True)
    
    saved_hashes = set()
    
    annotated_img = image.copy()
    saved_images = []

    results = model(image, conf=0.4, classes=[0], verbose=False)  # class 0 = person
    saved = 0

    try:
        if not results:
            logger.warning("No results returned from model")
            return {
                "total_detections": 0,
                "new_persons_saved": 0,
                "saved_images": [],
                "session_id": session_id,
                "type": "image"
            }

        boxes = results[0].boxes
        logger.info(f"YOLO detected {len(boxes)} items")

        for i, box in enumerate(boxes):
            try:
                # Ensure coordinates are on CPU and converted to int
                coords = box.xyxy[0].cpu().numpy().astype(int)
                x1, y1, x2, y2 = coords
                
                # Draw bounding box on annotated image (using original coords)
                cv2.rectangle(annotated_img, (x1, y1), (x2, y2), (0, 255, 0), 2)
                
                # =========================================================
                # 🌟 HIGH QUALITY CROP LOGIC
                # =========================================================
                h, w, _ = image.shape
                
                # Add padding (25%)
                pad = int(0.25 * (x2 - x1))
                
                x1_p = max(0, x1 - pad)
                y1_p = max(0, y1 - pad)
                x2_p = min(w, x2 + pad)
                y2_p = min(h, y2 + pad)
                
                crop = image[y1_p:y2_p, x1_p:x2_p]

                if crop.size == 0:
                    logger.warning("Empty crop detected, skipping")
                    continue

                # Optional upscale (2x)
                if crop.shape[0] > 0 and crop.shape[1] > 0:
                    crop = cv2.resize(
                        crop,
                        None,
                        fx=2,
                        fy=2,
                        interpolation=cv2.INTER_CUBIC
                    )

                img_hash = compute_image_hash(crop)
                if img_hash in saved_hashes:
                    continue

                saved_hashes.add(img_hash)
                filename = f"face_{saved + 1}.png"  # Save as PNG
                cv2.imwrite(str(session_dir / filename), crop) # PNG is lossless by default
                saved_images.append(f"{session_id}/{filename}")
                saved += 1
            except Exception as e:
                logger.error(f"Error processing box {i}: {e}")
                continue
                
        # Save the annotated full image
        annotated_filename = "annotated.jpg"
        cv2.imwrite(str(session_dir / annotated_filename), annotated_img)
        
        return {
            "total_detections": len(boxes),
            "new_persons_saved": saved,
            "saved_images": saved_images,
            "annotated_image": f"{session_id}/{annotated_filename}",
            "session_id": session_id,
            "type": "image"
        }

    except Exception as e:
        logger.exception("Critical error in detect_persons_image loop")
        raise e

# ============================================================
# 🎥 VIDEO PERSON DETECTION (FRAME SKIP ENABLED)
# ============================================================
def detect_persons_video(video_path: str, frame_skip: int = 10):
    if model is None:
        logger.error("YOLOv8 model is not loaded")
        raise ValueError("YOLOv8 model not loaded")

    logger.debug(f"Opening video file: {video_path}")
    cap = cv2.VideoCapture(video_path)
    if not cap.isOpened():
        logger.error("Could not open video file")
        raise ValueError("Could not open video")
    
    session_id = str(uuid.uuid4())
    session_dir = STORAGE_DIR / session_id
    session_dir.mkdir(parents=True, exist_ok=True)
    logger.info(f"Created session directory: {session_dir}")
    
    saved_hashes = set()

    frame_idx = 0
    processed_frames = 0
    saved = 0

    fps = cap.get(cv2.CAP_PROP_FPS)
    total_frames = int(cap.get(cv2.CAP_PROP_FRAME_COUNT))
    logger.info(f"Video Info: FPS={fps}, Total Frames={total_frames}")

    saved_images = []

    while True:
        ret, frame = cap.read()
        if not ret:
            break

        # ⏩ SKIP FRAMES FOR SPEED
        if frame_idx % (frame_skip + 1) != 0:
            frame_idx += 1
            continue

        processed_frames += 1
        results = model(frame, conf=0.4, classes=[0], verbose=False)

        for box in results[0].boxes:
            x1, y1, x2, y2 = map(int, box.xyxy[0])
            # Draw bounding box on annotated (optional, skipping for video speed)
            
            # =========================================================
            # 🌟 HIGH QUALITY CROP LOGIC
            # =========================================================
            h, w, _ = frame.shape
            
            # Add padding (25%)
            pad = int(0.25 * (x2 - x1))
            
            x1_p = max(0, x1 - pad)
            y1_p = max(0, y1 - pad)
            x2_p = min(w, x2 + pad)
            y2_p = min(h, y2 + pad)
            
            crop = frame[y1_p:y2_p, x1_p:x2_p]

            if crop.size == 0:
                continue

             # Optional upscale (2x)
            if crop.shape[0] > 0 and crop.shape[1] > 0:
                crop = cv2.resize(
                    crop,
                    None,
                    fx=2,
                    fy=2,
                    interpolation=cv2.INTER_CUBIC
                )

            img_hash = compute_image_hash(crop)
            if img_hash in saved_hashes:
                continue

            saved_hashes.add(img_hash)
            filename = f"face_{saved + 1}.png" # Save as PNG
            save_path = session_dir / filename
            cv2.imwrite(str(save_path), crop)
            saved += 1
            saved_images.append(f"{session_id}/{filename}")
            logger.debug(f"Saved new face: {save_path.name}")

        if processed_frames % 10 == 0:
             logger.debug(f"Processed {processed_frames} frames...")

        frame_idx += 1

    cap.release()
    logger.success(f"Video detection finished. Processed {processed_frames} frames, Saved {saved} unique persons.")

    return {
        "processed_frames": processed_frames,
        "new_persons_saved": saved,
        "saved_images": saved_images,
        "session_id": session_id,
        "type": "video"
    }

def create_persons_zip(session_id: str):
    session_dir = STORAGE_DIR / session_id
    if not session_dir.exists():
        raise ValueError("Session not found")
        
    zip_path = STORAGE_DIR / f"{session_id}"
    shutil.make_archive(str(zip_path), 'zip', session_dir)
    return f"{zip_path}.zip"
