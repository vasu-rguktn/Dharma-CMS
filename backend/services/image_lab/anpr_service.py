import cv2
import numpy as np
from ultralytics import YOLO
import easyocr
import imageio
from typing import Dict
from loguru import logger
from pathlib import Path


from utils.file_utils import read_image, save_video, get_video_info
from utils.anpr_utils import read_license_plate, format_license, license_complies_format

# ============================================================
# 🔐 PyTorch 2.6+ SAFE GLOBALS (REQUIRED FOR YOLO)
# ============================================================


# ============================================================
# 📦 LOAD YOLO LICENSE PLATE MODEL (SAFE + PORTABLE)
# ============================================================
BASE_DIR = Path(__file__).resolve().parents[2]
MODEL_PATH = BASE_DIR / "models" / "license_plate_detector.pt"

try:
    logger.info(f"Loading YOLO model from: {MODEL_PATH}")
    logger.info(f"Model exists: {MODEL_PATH.exists()}")
    model = YOLO(str(MODEL_PATH))
    logger.success("YOLO license plate model loaded successfully")
except Exception:
    logger.error("FAILED TO LOAD YOLO LICENSE PLATE MODEL", exc_info=True)
    model = None

# ============================================================
# 🔤 OCR INITIALIZATION
# ============================================================
reader = easyocr.Reader(['en'], gpu=False)

# ============================================================
# 🖼 IMAGE PLATE DETECTION
# ============================================================
def detect_plate_image(file) -> Dict:
    try:
        img = read_image(file)
        if img is None:
            raise ValueError("Could not read image")

        if model is None:
            raise ValueError("License plate detection model not available")

        # Create a copy for drawing
        draw_img = img.copy()

        results = model(img, conf=0.25)
        plates = []

        for box in results[0].boxes:
            x1, y1, x2, y2 = map(int, box.xyxy[0])
            confidence = float(box.conf[0])

            # Draw bounding box
            cv2.rectangle(draw_img, (x1, y1), (x2, y2), (0, 255, 0), 2)

            crop = img[y1:y2, x1:x2]
            if crop.size == 0:
                continue

            text, score = read_license_plate(crop)

            if text:
                # Add text to image
                cv2.putText(draw_img, text, (x1, y1 - 10), cv2.FONT_HERSHEY_SIMPLEX, 0.9, (0, 255, 0), 2)
                
                plates.append({
                    "bbox": [x1, y1, x2, y2],
                    "text": text,
                    "confidence": confidence,
                    "text_score": float(score) if score else 0.0
                })
            else:
                detections = reader.readtext(crop)
                if detections:
                    ocr_text = detections[0][1].upper().replace(" ", "")
                    # Try to format if it looks close
                    if len(ocr_text) >= 4: # Basic check
                         ocr_text = format_license(ocr_text)
                    
                    if ocr_text:
                        # Add text to image
                        cv2.putText(draw_img, ocr_text, (x1, y1 - 10), cv2.FONT_HERSHEY_SIMPLEX, 0.9, (0, 255, 0), 2)

                        plates.append({
                            "bbox": [x1, y1, x2, y2],
                            "text": ocr_text,
                            "confidence": confidence,
                            "text_score": float(detections[0][2])
                        })
        
        # Convert annotated image to base64
        from utils.file_utils import image_to_base64
        img_base64 = image_to_base64(draw_img)

        return {
            "status": "success",
            "plates": plates,
            "count": len(plates),
            "type": "image",
            "image": img_base64
        }

    except Exception as e:
        logger.error(f"Error in image plate detection: {str(e)}")
        raise ValueError(f"Image plate detection failed: {str(e)}")

# ============================================================
# 🎥 VIDEO PLATE DETECTION
# ============================================================
def detect_plate_video(file, frame_skip: int = 10) -> Dict:
    try:
        if hasattr(file, "seek"):
            file.seek(0)

        video_path = save_video(file)
        logger.info(f"Video saved to: {video_path}")

        video_info = get_video_info(video_path)
        fps = video_info["fps"]
        frame_count = video_info["frame_count"]

        cap = cv2.VideoCapture(video_path)
        if not cap.isOpened():
            raise ValueError("Could not open video")

        if model is None:
            raise ValueError("License plate detection model not available")

        all_plates = []
        frame_number = 0
        processed_frames = 0

        while True:
            ret, frame = cap.read()
            if not ret:
                break

            if frame_number % (frame_skip + 1) != 0:
                frame_number += 1
                continue

            processed_frames += 1
            results = model(frame, conf=0.25)
            frame_plates = []

            for box in results[0].boxes:
                x1, y1, x2, y2 = map(int, box.xyxy[0])
                confidence = float(box.conf[0])

                crop = frame[y1:y2, x1:x2]
                if crop.size == 0:
                    continue

                text, score = read_license_plate(crop)

                if text:
                    frame_plates.append({
                        "bbox": [x1, y1, x2, y2],
                        "text": text,
                        "confidence": confidence,
                        "text_score": float(score) if score else 0.0
                    })
                else:
                    detections = reader.readtext(crop)
                    if detections:
                        ocr_text = detections[0][1].upper().replace(" ", "")
                        if ocr_text:
                            frame_plates.append({
                                "bbox": [x1, y1, x2, y2],
                                "text": ocr_text,
                                "confidence": confidence,
                                "text_score": float(detections[0][2])
                            })

            if frame_plates:
                all_plates.append({
                    "frame": frame_number,
                    "timestamp": frame_number / fps if fps else 0,
                    "plates": frame_plates
                })

            frame_number += 1

        cap.release()

        unique_plates = {}
        for frame_data in all_plates:
            for plate in frame_data["plates"]:
                text = plate["text"]
                if text not in unique_plates:
                    unique_plates[text] = {
                        "text": text,
                        "first_seen_frame": frame_data["frame"],
                        "first_seen_timestamp": frame_data["timestamp"],
                        "detections": []
                    }
                unique_plates[text]["detections"].append({
                    "frame": frame_data["frame"],
                    "timestamp": frame_data["timestamp"],
                    "bbox": plate["bbox"],
                    "confidence": plate["confidence"],
                    "text_score": plate["text_score"]
                })

        # Helper to convert detections to consistent format for drawing
        def draw_plates_on_frame(frame_img, frame_detections):
            for plate in frame_detections:
                 x1, y1, x2, y2 = map(int, plate["bbox"])
                 text = plate["text"]
                 cv2.rectangle(frame_img, (x1, y1), (x2, y2), (0, 255, 0), 2)
                 cv2.putText(frame_img, text, (x1, y1 - 10), cv2.FONT_HERSHEY_SIMPLEX, 0.9, (0, 255, 0), 2)
            return frame_img

        # Initialize Video Writer
        # Use imageio with FFMPEG backend for guaranteed H.264 (avc1) encoding
        # This resolves issues where OpenCV on Windows lacks valid H.264 encoders.
        output_filename = f"processed_{Path(video_path).stem}.mp4"
        # Ensure absolute path for the output directory
        output_dir = BASE_DIR / "temp_videos"
        if not output_dir.exists():
            output_dir.mkdir(parents=True, exist_ok=True)
            
        output_path = str(output_dir / output_filename)
        logger.info(f"Writing processed video to: {output_path}")
        
        try:
             # macro_block_size=None allows arbitrary resolutions
             # pixelformat='yuv420p' is CRITICAL for browser/mobile compatibility
             writer = imageio.get_writer(
                 output_path, 
                 fps=fps, 
                 codec='libx264', 
                 macro_block_size=None,
                 pixelformat='yuv420p'
             )
        except Exception as e:
             logger.error(f"Failed to initialize imageio writer: {e}")
             raise ValueError(f"Video writer failed: {e}")

        # We need to re-read the video to write frames.
        cap.set(cv2.CAP_PROP_POS_FRAMES, 0)
        
        current_frame_idx = 0
        last_detections = [] 

        while True:
            ret, frame = cap.read()
            if not ret:
                break
            
            # Find detections for this frame in our results
            current_frame_detections = []
            for item in all_plates:
                if item["frame"] == current_frame_idx:
                    current_frame_detections = item["plates"]
                    last_detections = current_frame_detections
                    break
            
            frame_to_write = frame.copy()
            
            # Draw detections
            frame_to_write = draw_plates_on_frame(frame_to_write, last_detections)
             
            # Convert BGR (OpenCV) to RGB (imageio)
            frame_rgb = cv2.cvtColor(frame_to_write, cv2.COLOR_BGR2RGB)
            writer.append_data(frame_rgb)
            
            current_frame_idx += 1

        writer.close()
        cap.release()

        return {
            "status": "success",
            "total_frames": frame_count,
            "processed_frames": processed_frames,
            "frames_with_plates": len(all_plates),
            "unique_plates": list(unique_plates.values()),
            "all_detections": all_plates,
            "type": "video",
            "video_filename": output_filename # Return filename to construct URL
        }

    except Exception as e:
        logger.error(f"Error in video plate detection: {str(e)}")
        raise ValueError(f"Video plate detection failed: {str(e)}")

# ============================================================
# 🔁 MAIN ENTRY
# ============================================================
def detect_plate(file, is_video: bool = False, frame_skip: int = 10) -> Dict:
    if is_video:
        return detect_plate_video(file, frame_skip=frame_skip)
    else:
        return detect_plate_image(file)
