import cv2
import numpy as np
from typing import Optional
from utils.file_utils import read_image, save_temp_image, image_to_base64
from utils.image_utils import denoise, deblur, colorize, sharpen, low_light_boost, upscale
from loguru import logger

def enhance_image(
    file,
    denoise_enabled: bool = False,
    deblur_enabled: bool = False,
    colorize_enabled: bool = False,
    sharpen_enabled: bool = False,
    low_light_enabled: bool = False,
    upscale_enabled: bool = False,
    denoise_strength: int = 10,
    deblur_kernel_size: int = 15,
    colorize_saturation: float = 1.5,
    sharpen_strength: float = 1.0,
    low_light_gamma: float = 1.2,
    upscale_factor: float = 2.0,
    return_base64: bool = False
) -> dict:
    """
    Enhance image with selected operations.
    Operations are applied in the following order for best results:
    1. Denoise (if enabled)
    2. Deblur (if enabled)
    3. Colorize (if enabled)
    4. Sharpen (if enabled)
    5. Low light boost (if enabled)
    6. Upscale (if enabled)
    
    Args:
        file: UploadFile object or file path
        denoise_enabled: Enable denoising
        deblur_enabled: Enable deblurring
        colorize_enabled: Enable colorization/saturation enhancement
        sharpen_enabled: Enable sharpening
        low_light_enabled: Enable low-light enhancement
        upscale_enabled: Enable upscaling
        denoise_strength: Denoising strength (1-30)
        deblur_kernel_size: Deblur kernel size (should be odd, default 15)
        colorize_saturation: Saturation factor (1.0 = no change, >1.0 = more saturated)
        sharpen_strength: Sharpening strength (0.5-2.0)
        low_light_gamma: Gamma correction value for low-light boost
        upscale_factor: Scale factor for upscaling
        return_base64: If True, return base64 encoded image instead of file path
        
    Returns:
        Dictionary with status and output (either path or base64)
    """
    try:
        # Read image
        logger.info("Reading image for enhancement")
        # Handle different file types: bytes, file-like object, or file path
        if isinstance(file, bytes):
            # Direct bytes
            img = read_image(file)
        elif hasattr(file, 'read'):
            # File-like object (UploadFile, FileWrapper, etc.)
            file_bytes = file.read()
            if not file_bytes:
                raise ValueError("File read returned empty bytes")
            img = read_image(file_bytes)
        else:
            # File path string
            img = read_image(file)
        
        if img is None:
            raise ValueError("Could not read image - cv2.imdecode returned None")
        
        original_shape = img.shape
        logger.info(f"Original image shape: {original_shape}, dtype: {img.dtype}")
        
        # Apply enhancements in optimal order
        enhancements_applied = []
        
        if denoise_enabled:
            logger.info(f"Applying denoise (strength={denoise_strength})")
            img = denoise(img, strength=denoise_strength)
            enhancements_applied.append("denoise")
            logger.info(f"Denoise applied successfully, shape: {img.shape}")
        
        if deblur_enabled:
            logger.info(f"Applying deblur (kernel_size={deblur_kernel_size})")
            img = deblur(img, kernel_size=deblur_kernel_size)
            enhancements_applied.append("deblur")
            logger.info(f"Deblur applied successfully, shape: {img.shape}")
        
        if colorize_enabled:
            logger.info(f"Applying colorize (saturation={colorize_saturation})")
            img = colorize(img, saturation_factor=colorize_saturation)
            enhancements_applied.append("colorize")
            logger.info(f"Colorize applied successfully, shape: {img.shape}")
        
        if sharpen_enabled:
            logger.info(f"Applying sharpen (strength={sharpen_strength})")
            img = sharpen(img, strength=sharpen_strength)
            enhancements_applied.append("sharpen")
            logger.info(f"Sharpen applied successfully, shape: {img.shape}")
        
        if low_light_enabled:
            logger.info(f"Applying low-light boost (gamma={low_light_gamma})")
            img = low_light_boost(img, gamma=low_light_gamma)
            enhancements_applied.append("low_light")
            logger.info(f"Low-light boost applied successfully, shape: {img.shape}")
        
        if upscale_enabled:
            logger.info(f"Applying upscale (factor={upscale_factor})")
            img = upscale(img, scale_factor=upscale_factor)
            enhancements_applied.append("upscale")
            logger.info(f"Upscale applied successfully, shape: {img.shape}")
        
        final_shape = img.shape
        logger.info(f"Enhancement complete. Applied: {enhancements_applied}, Final shape: {final_shape}")
        
        if not enhancements_applied:
            logger.warning("No enhancements were applied - image returned as-is")
        
        # Return result
        if return_base64:
            img_base64 = image_to_base64(img)
            return {
                "status": "success",
                "image_base64": img_base64,
                "original_shape": original_shape,
                "final_shape": final_shape
            }
        else:
            output_path = save_temp_image(img)
            return {
                "status": "success",
                "output_path": output_path,
                "original_shape": original_shape,
                "final_shape": final_shape
            }
            
    except Exception as e:
        logger.error(f"Error enhancing image: {str(e)}")
        raise ValueError(f"Image enhancement failed: {str(e)}")
