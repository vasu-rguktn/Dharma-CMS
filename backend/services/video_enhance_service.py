import cv2
import numpy as np
from typing import Optional, Dict, Tuple
from pathlib import Path
import uuid
from loguru import logger
from utils.file_utils import save_video, get_video_info
from utils.video_utils import (
    denoise_frame,
    deblur_frame,
    upscale_frame,
    upscale_to_resolution,
    get_resolution_preset,
    sharpen_frame,
    low_light_boost_frame,
    stabilize_frame,
    enhance_contrast_frame
)


def enhance_video(
    file,
    denoise_enabled: bool = False,
    deblur_enabled: bool = False,
    upscale_enabled: bool = False,
    sharpen_enabled: bool = False,
    low_light_enabled: bool = False,
    stabilize_enabled: bool = False,
    contrast_enabled: bool = False,
    denoise_strength: int = 10,
    deblur_kernel_size: int = 15,
    upscale_factor: float = 2.0,
    upscale_preset: Optional[str] = None,
    upscale_method: str = "cubic",
    sharpen_strength: float = 1.0,
    low_light_gamma: float = 1.2,
    contrast_factor: float = 1.2,
    output_format: str = "mp4",
    output_quality: int = 23,  # Lower = better quality (0-51, default 23)
    maintain_fps: bool = True
) -> dict:
    """
    Enhance video with selected operations.
    Operations are applied frame-by-frame in the following order for best results:
    1. Denoise (if enabled)
    2. Deblur (if enabled)
    3. Sharpen (if enabled)
    4. Low light boost (if enabled)
    5. Contrast enhancement (if enabled)
    6. Upscale (if enabled) - applied last to avoid processing larger frames unnecessarily
    7. Stabilization (if enabled) - applied with temporal smoothing
    
    Args:
        file: UploadFile object, file path, or bytes
        denoise_enabled: Enable denoising
        deblur_enabled: Enable deblurring
        upscale_enabled: Enable upscaling
        sharpen_enabled: Enable sharpening
        low_light_enabled: Enable low-light enhancement
        stabilize_enabled: Enable temporal stabilization
        contrast_enabled: Enable contrast enhancement
        denoise_strength: Denoising strength (1-30)
        deblur_kernel_size: Deblur kernel size (should be odd, default 15)
        upscale_factor: Scale factor for upscaling (1.1-4.0)
        upscale_preset: Resolution preset ('360p', '480p', '720p', '1080p', '2k', '4k') - overrides upscale_factor
        upscale_method: Interpolation method ('cubic', 'lanczos', 'linear', 'nearest')
        sharpen_strength: Sharpening strength (0.5-2.0)
        low_light_gamma: Gamma correction value for low-light boost
        contrast_factor: Contrast enhancement factor (1.0-3.0)
        output_format: Output video format ('mp4', 'avi', 'mov')
        output_quality: Output quality (0-51, lower = better, default 23)
        maintain_fps: Whether to maintain original FPS
        
    Returns:
        Dictionary with status and output video path
    """
    try:
        # Save video file
        logger.info("Saving uploaded video file")
        # Reset file pointer if it's a file-like object
        if hasattr(file, 'seek'):
            file.seek(0)
        video_path = save_video(file)
        logger.info(f"Video saved to: {video_path}")
        
        # Get video information
        video_info = get_video_info(video_path)
        original_width = video_info["width"]
        original_height = video_info["height"]
        original_fps = video_info["fps"]
        frame_count = video_info["frame_count"]
        
        logger.info(
            f"Video info: {original_width}x{original_height}, "
            f"FPS: {original_fps}, Frames: {frame_count}"
        )
        
        # Open video
        cap = cv2.VideoCapture(video_path)
        if not cap.isOpened():
            raise ValueError(f"Could not open video file: {video_path}")
        
        # Determine output dimensions
        output_width = original_width
        output_height = original_height
        
        if upscale_enabled:
            if upscale_preset:
                # Use preset resolution
                target_width, target_height = get_resolution_preset(upscale_preset)
                output_width = target_width
                output_height = target_height
                logger.info(f"Upscaling to preset: {upscale_preset} ({target_width}x{target_height})")
            else:
                # Use scale factor
                output_width = int(original_width * upscale_factor)
                output_height = int(original_height * upscale_factor)
                logger.info(f"Upscaling by factor: {upscale_factor} ({output_width}x{output_height})")
        
        # Ensure deblur_kernel_size is odd
        if deblur_kernel_size % 2 == 0:
            deblur_kernel_size += 1
        
        # Setup output video writer
        output_fps = original_fps if maintain_fps else 30.0
        if output_fps <= 0:
            output_fps = 30.0  # Default FPS if not available
        
        # Create output directory
        output_dir = Path("temp_videos")
        output_dir.mkdir(exist_ok=True)
        output_filename = f"enhanced_{uuid.uuid4().hex[:8]}.{output_format}"
        output_path = str(output_dir / output_filename)
        
        # Video codec setup
        fourcc_map = {
            "mp4": cv2.VideoWriter_fourcc(*"mp4v"),
            "avi": cv2.VideoWriter_fourcc(*"XVID"),
            "mov": cv2.VideoWriter_fourcc(*"mp4v"),
        }
        fourcc = fourcc_map.get(output_format.lower(), cv2.VideoWriter_fourcc(*"mp4v"))
        
        writer = cv2.VideoWriter(
            output_path,
            fourcc,
            output_fps,
            (output_width, output_height)
        )
        
        if not writer.isOpened():
            raise ValueError(f"Could not create output video writer: {output_path}")
        
        # Process frames
        frame_number = 0
        prev_frame = None
        enhancements_applied = []
        
        if denoise_enabled:
            enhancements_applied.append("denoise")
        if deblur_enabled:
            enhancements_applied.append("deblur")
        if sharpen_enabled:
            enhancements_applied.append("sharpen")
        if low_light_enabled:
            enhancements_applied.append("low_light")
        if contrast_enabled:
            enhancements_applied.append("contrast")
        if upscale_enabled:
            enhancements_applied.append("upscale")
        if stabilize_enabled:
            enhancements_applied.append("stabilize")
        
        logger.info(f"Processing video with enhancements: {enhancements_applied}")
        
        while True:
            ret, frame = cap.read()
            if not ret:
                break
            
            frame_number += 1
            
            # Log progress every 30 frames
            if frame_number % 30 == 0:
                progress = (frame_number / frame_count) * 100 if frame_count > 0 else 0
                logger.info(f"Processing frame {frame_number}/{frame_count} ({progress:.1f}%)")
            
            # Apply enhancements in optimal order
            try:
                # 1. Denoise
                if denoise_enabled:
                    frame = denoise_frame(frame, strength=denoise_strength)
                
                # 2. Deblur
                if deblur_enabled:
                    frame = deblur_frame(frame, kernel_size=deblur_kernel_size)
                
                # 3. Sharpen
                if sharpen_enabled:
                    frame = sharpen_frame(frame, strength=sharpen_strength)
                
                # 4. Low light boost
                if low_light_enabled:
                    frame = low_light_boost_frame(frame, gamma=low_light_gamma)
                
                # 5. Contrast enhancement
                if contrast_enabled:
                    frame = enhance_contrast_frame(frame, contrast=contrast_factor)
                
                # 6. Upscale (applied last to avoid processing larger frames unnecessarily)
                if upscale_enabled:
                    if upscale_preset:
                        frame = upscale_to_resolution(
                            frame,
                            output_width,
                            output_height,
                            method=upscale_method
                        )
                    else:
                        frame = upscale_frame(frame, scale_factor=upscale_factor, method=upscale_method)
                
                # 7. Stabilization (temporal smoothing)
                if stabilize_enabled and prev_frame is not None:
                    frame = stabilize_frame(frame, prev_frame, alpha=0.3)
                
                # Write frame
                writer.write(frame)
                
                # Store previous frame for stabilization
                if stabilize_enabled:
                    prev_frame = frame.copy()
                    
            except Exception as e:
                logger.error(f"Error processing frame {frame_number}: {str(e)}")
                # Continue with next frame
                continue
        
        # Release resources
        cap.release()
        writer.release()
        
        logger.info(f"Video enhancement complete. Output: {output_path}")
        
        # Get output video info
        output_info = get_video_info(output_path)
        
        return {
            "status": "success",
            "output_path": output_path,
            "original_resolution": f"{original_width}x{original_height}",
            "final_resolution": f"{output_info['width']}x{output_info['height']}",
            "original_fps": original_fps,
            "final_fps": output_info["fps"],
            "frame_count": frame_number,
            "enhancements_applied": enhancements_applied,
            "message": f"Video enhanced successfully with {len(enhancements_applied)} enhancement(s)"
        }
        
    except ValueError as e:
        logger.error(f"ValueError in video enhancement: {str(e)}")
        raise
    except Exception as e:
        logger.error(f"Unexpected error in video enhancement: {str(e)}")
        import traceback
        logger.error(traceback.format_exc())
        raise ValueError(f"Video enhancement failed: {str(e)}")
