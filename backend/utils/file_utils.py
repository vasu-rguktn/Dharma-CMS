import os
import cv2
import numpy as np
from pathlib import Path
from typing import Optional
from tempfile import NamedTemporaryFile
import base64
from io import BytesIO

def read_image(file) -> np.ndarray:
    """
    Read image from UploadFile or file path.
    
    Args:
        file: FastAPI UploadFile object or file path string or bytes
        
    Returns:
        numpy array of image (BGR format for OpenCV)
    """
    # Handle bytes first (most common case after our fix)
    if isinstance(file, bytes):
        if len(file) == 0:
            raise ValueError("Empty file bytes provided")
        nparr = np.frombuffer(file, np.uint8)
        img = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
        if img is None:
            raise ValueError(f"Could not decode image from bytes (length: {len(file)})")
        return img
    
    # Handle file-like objects
    if hasattr(file, 'read'):
        # It's an UploadFile or file-like object - read from it
        if hasattr(file, 'file'):
            contents = file.file.read()
        else:
            contents = file.read()
        
        if not contents or len(contents) == 0:
            raise ValueError("File read returned empty contents")
        
        nparr = np.frombuffer(contents, np.uint8)
        img = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
        if img is None:
            raise ValueError(f"Could not decode image from file-like object (length: {len(contents)})")
        return img
    
    # Handle file path string
    if isinstance(file, str):
        img = cv2.imread(file, cv2.IMREAD_COLOR)
        if img is None:
            raise ValueError(f"Could not read image from path: {file}")
        return img
    
    # Unknown type
    raise ValueError(f"Unsupported file type: {type(file)}")

def save_temp_image(img: np.ndarray, suffix: str = ".jpg") -> str:
    """
    Save image to temporary file and return path.
    
    Args:
        img: numpy array of image (BGR format)
        suffix: file extension (.jpg, .png, etc.)
        
    Returns:
        path to saved temporary file
    """
    # Create temp directory if it doesn't exist
    temp_dir = Path("temp_images")
    temp_dir.mkdir(exist_ok=True)
    
    # Generate unique filename
    import uuid
    filename = f"enhanced_{uuid.uuid4().hex[:8]}{suffix}"
    filepath = temp_dir / filename
    
    # Save image
    cv2.imwrite(str(filepath), img)
    
    return str(filepath)

def image_to_base64(img: np.ndarray, format: str = "JPEG") -> str:
    """
    Convert numpy array image to base64 string.
    
    Args:
        img: numpy array of image (BGR format)
        format: image format (JPEG, PNG)
        
    Returns:
        base64 encoded image string
    """
    # Convert BGR to RGB for PIL
    img_rgb = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)
    
    # Encode to JPEG/PNG
    if format == "PNG":
        _, buffer = cv2.imencode('.png', img)
    else:
        _, buffer = cv2.imencode('.jpg', img, [cv2.IMWRITE_JPEG_QUALITY, 95])
    
    # Convert to base64
    img_base64 = base64.b64encode(buffer).decode('utf-8')
    return img_base64
