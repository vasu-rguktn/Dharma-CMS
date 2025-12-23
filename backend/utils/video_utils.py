import cv2
import numpy as np
from typing import Tuple, Optional

def denoise_frame(frame: np.ndarray, strength: int = 10) -> np.ndarray:
    """
    Remove noise from video frame using Non-Local Means Denoising.
    
    Args:
        frame: Input frame (BGR format)
        strength: Denoising strength (1-30, higher = more aggressive)
        
    Returns:
        Denoised frame
    """
    if frame is None:
        raise ValueError("Input frame is None")
    
    if len(frame.shape) != 3 or frame.shape[2] != 3:
        raise ValueError(f"Expected 3-channel BGR frame, got shape: {frame.shape}")
    
    try:
        # Non-Local Means Denoising for colored images
        denoised = cv2.fastNlMeansDenoisingColored(
            frame,
            None,
            h=strength,
            hColor=strength,
            templateWindowSize=7,
            searchWindowSize=21
        )
        if denoised is None:
            raise ValueError("Denoising returned None")
        return denoised
    except Exception as e:
        raise ValueError(f"Denoising failed: {str(e)}")

def deblur_frame(frame: np.ndarray, kernel_size: int = 15) -> np.ndarray:
    """
    Reduce blur in video frame using Unsharp Masking.
    
    Args:
        frame: Input frame (BGR format)
        kernel_size: Kernel size for unsharp masking (should be odd, default 15)
        
    Returns:
        Deblurred frame
    """
    if frame is None:
        raise ValueError("Input frame is None")
    
    if len(frame.shape) != 3 or frame.shape[2] != 3:
        raise ValueError(f"Expected 3-channel BGR frame, got shape: {frame.shape}")
    
    # Ensure kernel_size is odd
    if kernel_size % 2 == 0:
        kernel_size += 1
    
    try:
        # Apply Gaussian blur to create a mask
        gaussian = cv2.GaussianBlur(frame, (kernel_size, kernel_size), 0)
        
        # Unsharp masking: original + (original - blurred) * amount
        unsharp = cv2.addWeighted(frame, 1.5, gaussian, -0.5, 0)
        
        if unsharp is None:
            raise ValueError("Deblurring returned None")
        
        return unsharp
    except Exception as e:
        raise ValueError(f"Deblurring failed: {str(e)}")

def upscale_frame(frame: np.ndarray, scale_factor: float = 2.0, method: str = "cubic") -> np.ndarray:
    """
    Upscale video frame using interpolation or super resolution.
    
    Args:
        frame: Input frame (BGR format)
        scale_factor: Scale factor (2.0 = double size, 4.0 = 4x size)
        method: Interpolation method - 'cubic', 'lanczos', 'nearest', 'linear'
        
    Returns:
        Upscaled frame
    """
    if frame is None:
        raise ValueError("Input frame is None")
    
    if len(frame.shape) < 2:
        raise ValueError(f"Invalid frame shape: {frame.shape}")
    
    if scale_factor <= 1.0:
        raise ValueError(f"Scale factor must be > 1.0, got: {scale_factor}")
    
    try:
        height, width = frame.shape[:2]
        new_width = int(width * scale_factor)
        new_height = int(height * scale_factor)
        
        if new_width <= 0 or new_height <= 0:
            raise ValueError(f"Invalid dimensions after upscaling: {new_width}x{new_height}")
        
        # Select interpolation method
        interpolation_map = {
            "nearest": cv2.INTER_NEAREST,
            "linear": cv2.INTER_LINEAR,
            "cubic": cv2.INTER_CUBIC,
            "lanczos": cv2.INTER_LANCZOS4,
        }
        
        interpolation = interpolation_map.get(method.lower(), cv2.INTER_CUBIC)
        
        # Upscale frame
        upscaled = cv2.resize(frame, (new_width, new_height), interpolation=interpolation)
        
        if upscaled is None:
            raise ValueError("Upscaling returned None")
        
        return upscaled
    except Exception as e:
        raise ValueError(f"Upscaling failed: {str(e)}")

def upscale_to_resolution(frame: np.ndarray, target_width: int, target_height: int, method: str = "cubic") -> np.ndarray:
    """
    Upscale video frame to specific resolution (e.g., 360p to 2K).
    
    Args:
        frame: Input frame (BGR format)
        target_width: Target width in pixels
        target_height: Target height in pixels
        method: Interpolation method - 'cubic', 'lanczos', 'nearest', 'linear'
        
    Returns:
        Upscaled frame to target resolution
    """
    if frame is None:
        raise ValueError("Input frame is None")
    
    if len(frame.shape) < 2:
        raise ValueError(f"Invalid frame shape: {frame.shape}")
    
    if target_width <= 0 or target_height <= 0:
        raise ValueError(f"Invalid target dimensions: {target_width}x{target_height}")
    
    try:
        # Select interpolation method
        interpolation_map = {
            "nearest": cv2.INTER_NEAREST,
            "linear": cv2.INTER_LINEAR,
            "cubic": cv2.INTER_CUBIC,
            "lanczos": cv2.INTER_LANCZOS4,
        }
        
        interpolation = interpolation_map.get(method.lower(), cv2.INTER_CUBIC)
        
        # Upscale frame to target resolution
        upscaled = cv2.resize(frame, (target_width, target_height), interpolation=interpolation)
        
        if upscaled is None:
            raise ValueError("Upscaling returned None")
        
        return upscaled
    except Exception as e:
        raise ValueError(f"Upscaling to resolution failed: {str(e)}")

def get_resolution_preset(preset: str) -> Tuple[int, int]:
    """
    Get width and height for common resolution presets.
    
    Args:
        preset: Resolution preset - '360p', '480p', '720p', '1080p', '2k', '4k'
        
    Returns:
        Tuple of (width, height)
    """
    presets = {
        "360p": (640, 360),
        "480p": (854, 480),
        "720p": (1280, 720),
        "1080p": (1920, 1080),
        "2k": (2560, 1440),
        "4k": (3840, 2160),
    }
    
    preset_lower = preset.lower()
    if preset_lower not in presets:
        raise ValueError(f"Unknown resolution preset: {preset}. Available: {list(presets.keys())}")
    
    return presets[preset_lower]

def sharpen_frame(frame: np.ndarray, strength: float = 1.0) -> np.ndarray:
    """
    Sharpen video frame using kernel convolution.
    
    Args:
        frame: Input frame (BGR format)
        strength: Sharpening strength (0.5-2.0, default 1.0)
        
    Returns:
        Sharpened frame
    """
    if frame is None:
        raise ValueError("Input frame is None")
    
    if len(frame.shape) != 3 or frame.shape[2] != 3:
        raise ValueError(f"Expected 3-channel BGR frame, got shape: {frame.shape}")
    
    try:
        # Create sharpening kernel
        kernel = np.array([
            [0, -strength, 0],
            [-strength, 1 + 4*strength, -strength],
            [0, -strength, 0]
        ], dtype=np.float32)
        
        # Apply kernel
        sharpened = cv2.filter2D(frame, -1, kernel)
        
        if sharpened is None:
            raise ValueError("Sharpening returned None")
        
        # Clamp values to valid range
        sharpened = np.clip(sharpened, 0, 255).astype(np.uint8)
        
        return sharpened
    except Exception as e:
        raise ValueError(f"Sharpening failed: {str(e)}")

def low_light_boost_frame(frame: np.ndarray, gamma: float = 1.2) -> np.ndarray:
    """
    Enhance low-light video frame using gamma correction and CLAHE.
    
    Args:
        frame: Input frame (BGR format)
        gamma: Gamma correction value (1.0 = no change, <1.0 = brighter, >1.0 = darker)
        
    Returns:
        Enhanced frame
    """
    if frame is None:
        raise ValueError("Input frame is None")
    
    if len(frame.shape) != 3 or frame.shape[2] != 3:
        raise ValueError(f"Expected 3-channel BGR frame, got shape: {frame.shape}")
    
    try:
        # Gamma correction
        inv_gamma = 1.0 / gamma
        table = np.array([((i / 255.0) ** inv_gamma) * 255 for i in np.arange(0, 256)]).astype("uint8")
        corrected = cv2.LUT(frame, table)
        
        if corrected is None:
            raise ValueError("Gamma correction returned None")
        
        # Apply CLAHE (Contrast Limited Adaptive Histogram Equalization)
        lab = cv2.cvtColor(corrected, cv2.COLOR_BGR2LAB)
        l, a, b = cv2.split(lab)
        clahe = cv2.createCLAHE(clipLimit=2.0, tileGridSize=(8, 8))
        l = clahe.apply(l)
        enhanced = cv2.merge([l, a, b])
        enhanced = cv2.cvtColor(enhanced, cv2.COLOR_LAB2BGR)
        
        if enhanced is None:
            raise ValueError("CLAHE enhancement returned None")
        
        return enhanced
    except Exception as e:
        raise ValueError(f"Low-light boost failed: {str(e)}")

def stabilize_frame(frame: np.ndarray, prev_frame: Optional[np.ndarray] = None, alpha: float = 0.5) -> np.ndarray:
    """
    Apply temporal stabilization to reduce jitter between frames.
    
    Args:
        frame: Current frame (BGR format)
        prev_frame: Previous frame for temporal smoothing (optional)
        alpha: Smoothing factor (0.0-1.0, higher = more smoothing)
        
    Returns:
        Stabilized frame
    """
    if frame is None:
        raise ValueError("Input frame is None")
    
    if prev_frame is None:
        return frame
    
    try:
        # Temporal smoothing: blend current frame with previous frame
        stabilized = cv2.addWeighted(frame, 1.0 - alpha, prev_frame, alpha, 0)
        return stabilized
    except Exception as e:
        raise ValueError(f"Stabilization failed: {str(e)}")

def enhance_contrast_frame(frame: np.ndarray, contrast: float = 1.2) -> np.ndarray:
    """
    Enhance contrast of video frame.
    
    Args:
        frame: Input frame (BGR format)
        contrast: Contrast factor (1.0 = no change, >1.0 = more contrast)
        
    Returns:
        Contrast-enhanced frame
    """
    if frame is None:
        raise ValueError("Input frame is None")
    
    try:
        # Convert to float for processing
        frame_float = frame.astype(np.float32)
        
        # Apply contrast: (pixel - 128) * contrast + 128
        enhanced = (frame_float - 128) * contrast + 128
        
        # Clip to valid range and convert back
        enhanced = np.clip(enhanced, 0, 255).astype(np.uint8)
        
        return enhanced
    except Exception as e:
        raise ValueError(f"Contrast enhancement failed: {str(e)}")
