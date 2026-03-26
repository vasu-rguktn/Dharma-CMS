import cv2
import numpy as np
from typing import Tuple, Optional

def denoise(img: np.ndarray, strength: int = 10) -> np.ndarray:
    """
    Remove noise from image using Non-Local Means Denoising.
    
    Args:
        img: Input image (BGR format)
        strength: Denoising strength (1-30, higher = more aggressive)
        
    Returns:
        Denoised image
    """
    if img is None:
        raise ValueError("Input image is None")
    
    if len(img.shape) != 3 or img.shape[2] != 3:
        raise ValueError(f"Expected 3-channel BGR image, got shape: {img.shape}")
    
    # Non-Local Means Denoising
    # h: Filter strength for luminance component (higher = more denoising)
    # templateWindowSize: Size of template patch (should be odd, recommended 7)
    # searchWindowSize: Size of search window (should be odd, recommended 21)
    try:
        denoised = cv2.fastNlMeansDenoisingColored(
            img,
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

def deblur(img: np.ndarray, kernel_size: int = 15) -> np.ndarray:
    """
    Reduce blur in image using Wiener filter or Unsharp Masking.
    Uses Unsharp Masking for better results on general images.
    
    Args:
        img: Input image (BGR format)
        kernel_size: Kernel size for unsharp masking (should be odd, default 15)
        
    Returns:
        Deblurred image
    """
    if img is None:
        raise ValueError("Input image is None")
    
    if len(img.shape) != 3 or img.shape[2] != 3:
        raise ValueError(f"Expected 3-channel BGR image, got shape: {img.shape}")
    
    # Ensure kernel_size is odd
    if kernel_size % 2 == 0:
        kernel_size += 1
    
    try:
        # Apply Gaussian blur to create a mask
        gaussian = cv2.GaussianBlur(img, (kernel_size, kernel_size), 0)
        
        # Unsharp masking: original + (original - blurred) * amount
        unsharp = cv2.addWeighted(img, 1.5, gaussian, -0.5, 0)
        
        if unsharp is None:
            raise ValueError("Deblurring returned None")
        
        return unsharp
    except Exception as e:
        raise ValueError(f"Deblurring failed: {str(e)}")

def colorize(img: np.ndarray, saturation_factor: float = 1.5) -> np.ndarray:
    """
    Enhance/colorize image by adjusting saturation and color balance.
    For grayscale images, this won't add color but will enhance existing colors.
    
    Args:
        img: Input image (BGR format)
        saturation_factor: Factor to increase saturation (1.0 = no change, >1.0 = more saturated)
        
    Returns:
        Colorized/enhanced image
    """
    if img is None:
        raise ValueError("Input image is None")
    
    if len(img.shape) != 3 or img.shape[2] != 3:
        raise ValueError(f"Expected 3-channel BGR image, got shape: {img.shape}")
    
    try:
        # Convert BGR to HSV (Hue, Saturation, Value)
        hsv = cv2.cvtColor(img, cv2.COLOR_BGR2HSV).astype(np.float32)
        
        # Increase saturation
        hsv[:, :, 1] = hsv[:, :, 1] * saturation_factor
        hsv[:, :, 1] = np.clip(hsv[:, :, 1], 0, 255)
        
        # Convert back to BGR
        enhanced = cv2.cvtColor(hsv.astype(np.uint8), cv2.COLOR_HSV2BGR)
        
        if enhanced is None:
            raise ValueError("Colorization returned None")
        
        return enhanced
    except Exception as e:
        raise ValueError(f"Colorization failed: {str(e)}")

def sharpen(img: np.ndarray, strength: float = 1.0) -> np.ndarray:
    """
    Sharpen image using kernel convolution.
    
    Args:
        img: Input image (BGR format)
        strength: Sharpening strength (0.5-2.0, default 1.0)
        
    Returns:
        Sharpened image
    """
    if img is None:
        raise ValueError("Input image is None")
    
    if len(img.shape) != 3 or img.shape[2] != 3:
        raise ValueError(f"Expected 3-channel BGR image, got shape: {img.shape}")
    
    try:
        # Create sharpening kernel
        # Kernel: [[ 0, -1,  0],
        #          [-1,  5, -1],
        #          [ 0, -1,  0]]
        kernel = np.array([
            [0, -strength, 0],
            [-strength, 1 + 4*strength, -strength],
            [0, -strength, 0]
        ], dtype=np.float32)
        
        # Apply kernel
        sharpened = cv2.filter2D(img, -1, kernel)
        
        if sharpened is None:
            raise ValueError("Sharpening returned None")
        
        # Clamp values to valid range
        sharpened = np.clip(sharpened, 0, 255).astype(np.uint8)
        
        return sharpened
    except Exception as e:
        raise ValueError(f"Sharpening failed: {str(e)}")

def low_light_boost(img: np.ndarray, gamma: float = 1.2) -> np.ndarray:
    """
    Enhance low-light images using gamma correction and CLAHE.
    
    Args:
        img: Input image (BGR format)
        gamma: Gamma correction value (1.0 = no change, <1.0 = brighter, >1.0 = darker)
        
    Returns:
        Enhanced image
    """
    if img is None:
        raise ValueError("Input image is None")
    
    if len(img.shape) != 3 or img.shape[2] != 3:
        raise ValueError(f"Expected 3-channel BGR image, got shape: {img.shape}")
    
    try:
        # Gamma correction (for low-light, we want to brighten, so gamma < 1.0)
        # But the parameter is inverted: higher gamma = brighter for low-light
        inv_gamma = 1.0 / gamma
        table = np.array([((i / 255.0) ** inv_gamma) * 255 for i in np.arange(0, 256)]).astype("uint8")
        corrected = cv2.LUT(img, table)
        
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

def upscale(img: np.ndarray, scale_factor: float = 2.0) -> np.ndarray:
    """
    Upscale image using interpolation.
    
    Args:
        img: Input image (BGR format)
        scale_factor: Scale factor (2.0 = double size)
        
    Returns:
        Upscaled image
    """
    if img is None:
        raise ValueError("Input image is None")
    
    if len(img.shape) < 2:
        raise ValueError(f"Invalid image shape: {img.shape}")
    
    if scale_factor <= 1.0:
        raise ValueError(f"Scale factor must be > 1.0, got: {scale_factor}")
    
    try:
        height, width = img.shape[:2]
        new_width = int(width * scale_factor)
        new_height = int(height * scale_factor)
        
        if new_width <= 0 or new_height <= 0:
            raise ValueError(f"Invalid dimensions after upscaling: {new_width}x{new_height}")
        
        # Use INTER_CUBIC for better quality
        upscaled = cv2.resize(img, (new_width, new_height), interpolation=cv2.INTER_CUBIC)
        
        if upscaled is None:
            raise ValueError("Upscaling returned None")
        
        return upscaled
    except Exception as e:
        raise ValueError(f"Upscaling failed: {str(e)}")
