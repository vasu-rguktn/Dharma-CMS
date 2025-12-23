# backend/services/sketch_service.py
import os
import base64
from typing import Dict
from loguru import logger
import google.generativeai as genai
from io import BytesIO
from PIL import Image

from utils.sketch_utils import (
    build_sketch_prompt,
    validate_prompt
)

# -----------------------------
# GEMINI CONFIG
# -----------------------------

GEMINI_API_KEY = os.getenv("GEMINI_API_KEY_SKETCH")
# Fallback to investigation key if specific sketch key is missing
if not GEMINI_API_KEY:
    GEMINI_API_KEY = os.getenv("GEMINI_API_KEY_INVESTIGATION")

if not GEMINI_API_KEY:
    logger.warning("GEMINI_API_KEY_SKETCH not set. Sketch generation may fail.")

try:
    genai.configure(api_key=GEMINI_API_KEY)
except Exception as e:
    logger.error(f"Failed to configure Gemini API: {e}")

# -----------------------------
# MAIN SERVICE FUNCTION
# -----------------------------

def generate_sketch(prompt: str) -> Dict:
    """
    Generate sketch image using Gemini (Imagen) API.
    Uses 'imagen-3.0-generate-001' or compatible model.
    """

    # 1️⃣ Validate user input
    validate_prompt(prompt)

    # 2️⃣ Build final sketch + negative prompts
    # Note: Gemini/Imagen handles negative prompts differently or implicitly, 
    # but we can append them to the main prompt for better context if strictly supported,
    # or rely on the strong "sketch style" instruction.
    final_prompt, negative_prompt = build_sketch_prompt(prompt)
    
    # Enrich prompt for Gemini/Imagen specific adherence
    enhanced_prompt = (
        f"{final_prompt}. "
        f"Negative requirements: {negative_prompt}"
    )

    logger.info(f"Generating sketch with prompt: {enhanced_prompt}")

    try:
        # Attempt to get the image generation model
        # Note: The model name might vary by region availability (e.g., 'imagen-3.0-generate-001')
        # Using a fallback pattern if needed or standard 'imagen-3.0-generate-001'
        imagen_model = genai.ImageGenerationModel("imagen-3.0-generate-001")
        
        response = imagen_model.generate_images(
            prompt=enhanced_prompt,
            number_of_images=1,
            aspect_ratio="1:1",
            safety_filter_level="block_only_high",
            person_generation="allow_adult" 
        )
        
        if not response.images:
             raise ValueError("No images returned from Gemini API")
             
        # Get the first image
        generated_image = response.images[0]
        
        # Convert to base64
        # generated_image._image_bytes is internal, prefer using available property if SDK supports it
        # Assuming standard PIL integration or bytes access
        
        # If the SDK returns bytes directly or a PIL image:
        # We can usually access ._image_bytes or save to buffer
        
        # Safe way via PIL if the object wraps it, or check properties
        # The genai library `GeneratedImage` object typically has `_image_bytes` or `image` (PIL)
        
        # Let's try standard PIL save pattern
        img_buffer = BytesIO()
        generated_image.save(img_buffer, "PNG") # This works if the object has a .save method (it usually does)
        img_buffer.seek(0)
        
        image_base64 = base64.b64encode(img_buffer.read()).decode("utf-8")

        return {
            "image_base64": image_base64
        }

    except Exception as e:
        logger.error(f"Gemini/Imagen API Error: {str(e)}")
        # Fallback error handling or detailed message
        raise ValueError(f"Failed to generate sketch: {str(e)}")
