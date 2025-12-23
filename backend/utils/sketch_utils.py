

import re
from typing import Tuple

# -----------------------------
# CONSTANT PROMPT COMPONENTS
# -----------------------------

SKETCH_STYLE = (
    "forensic pencil sketch, black and white, "
    "hand drawn, line art, minimal shading, "
    "front facing portrait, neutral expression"
)

NEGATIVE_PROMPT = (
    "photorealistic, color, anime, cartoon, 3d render, "
    "oil painting, watercolor, blurry, low quality"
)

# -----------------------------
# PROMPT NORMALIZATION
# -----------------------------

def normalize_prompt(user_prompt: str) -> str:
    """
    Cleans and normalizes user input prompt
    """
    prompt = user_prompt.strip().lower()

    # Remove special characters except commas
    prompt = re.sub(r"[^a-z0-9, ]", "", prompt)

    # Collapse multiple spaces
    prompt = re.sub(r"\s+", " ", prompt)

    return prompt


# -----------------------------
# FINAL PROMPT BUILDER
# -----------------------------

def build_sketch_prompt(user_prompt: str) -> Tuple[str, str]:
    """
    Builds final Stable Diffusion compatible prompt
    """
    cleaned_prompt = normalize_prompt(user_prompt)

    final_prompt = f"{SKETCH_STYLE}, {cleaned_prompt}"

    return final_prompt, NEGATIVE_PROMPT


# -----------------------------
# BASIC SAFETY CHECK
# -----------------------------

def validate_prompt(user_prompt: str):
    """
    Blocks empty or meaningless prompts
    """
    if not user_prompt or len(user_prompt.strip()) < 5:
        raise ValueError("Prompt is too short")

    blocked_words = ["celebrity", "famous person", "real person"]
    for word in blocked_words:
        if word in user_prompt.lower():
            raise ValueError("Real person sketches are not allowed")
