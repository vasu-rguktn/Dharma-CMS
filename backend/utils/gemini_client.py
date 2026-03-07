"""
utils/gemini_client.py
======================
Gemini API Key Rotator + Batch Translation Utility

Provides:
  - GeminiKeyRotator: singleton that round-robins across 11 API keys,
    auto-rotating on 429 / ResourceExhausted with a single immediate retry.
  - batch_translate_fields(): translates all complaint fields in ONE Gemini call.

Usage:
    from utils.gemini_client import gemini_rotator, batch_translate_fields
"""

import os
import json
import threading
import time
import asyncio
from loguru import logger
from typing import Optional, List, Any
from utils.gemini_tracker import gemini_tracker

from google.generativeai.types import content_types
from dotenv import load_dotenv
import google.generativeai as genai
from gemini_key_manager import gemini_key_manager

# Note: Firestore keys are managed via gemini_key_manager

# Load .env so keys are available regardless of import order
load_dotenv(override=True)

# ---------------------------------------------------------------------------
# Key Rotator
# ---------------------------------------------------------------------------

class GeminiKeyRotator:
    """
    Singleton that manages multiple Gemini API keys.

    Keys are loaded from GEMINI_API_KEY_1 … GEMINI_API_KEY_11 in the env.
    Falls back to GEMINI_API_KEY / GEMINI_API_KEY_INVESTIGATION for
    backward-compatibility so no existing usage breaks.

    On ResourceExhausted (HTTP 429), rotates to the next key immediately
    and retries exactly once — preventing infinite retry storms.
    """

    _instance = None
    _singleton_lock = threading.Lock()

    def __new__(cls):
        with cls._singleton_lock:
            if cls._instance is None:
                instance = super().__new__(cls)
                instance._init()
                cls._instance = instance
        return cls._instance

    # ------------------------------------------------------------------
    def _init(self):
        self._lock = threading.Lock()
        # Proxy stats to preserve compatibility for existing monitoring endpoints
        self._stats = {
            "total_calls": 0,
            "total_rotations": 0,
            "total_errors": 0,
            "errors_per_key": {},
            "rotations_per_key": {},
        }
        logger.info("[GeminiKeyRotator] Initialized with Firestore backing.")

    # ------------------------------------------------------------------
    def _configure(self, index: int):
        """Apply the key at `index` to the genai SDK."""
        if not self.keys:
            return
        idx = index % len(self.keys)
        genai.configure(api_key=self.keys[idx])

    def _rotate(self) -> int:
        """Advance to the next key and configure it. Returns new index."""
        with self._lock:
            old_index = self._index
            self._index = (self._index + 1) % len(self.keys)
            new_index = self._index
            self._stats["total_rotations"] += 1
            self._stats["rotations_per_key"][old_index] = (
                self._stats["rotations_per_key"].get(old_index, 0) + 1
            )
        self._configure(new_index)
        logger.warning(
            f"[GeminiKeyRotator] Rate-limited on key #{old_index + 1} → "
            f"rotating to key #{new_index + 1}"
        )
        return new_index

    # ------------------------------------------------------------------
    def _is_rate_limit(self, exc: Exception) -> bool:
        """Detect 429 / ResourceExhausted from any exception type."""
        msg = str(exc).lower()
        return (
            "resourceexhausted" in msg
            or "429" in msg
            or "quota" in msg
            or "rate" in msg
        )

    # ------------------------------------------------------------------
    def generate_content(
        self,
        model_name: str,
        prompt,
        endpoint: str = "unknown",
        session_id: Optional[str] = None,
        **kwargs,
    ):
        """
        Blocking generate_content with automatic key rotation using GeminiKeyManager.
        """
        self._stats["total_calls"] += 1
        max_retries = gemini_key_manager.get_key_count() or 1
        
        for attempt in range(max_retries):
            key_info = gemini_key_manager.get_next_key()
            if not key_info:
                raise Exception("All Gemini keys are rate-limited or unavailable.")
            
            key_id = key_info["id"]
            api_key = key_info["key"]
            
            try:
                genai.configure(api_key=api_key)
                model = genai.GenerativeModel(model_name)
                response = model.generate_content(prompt, **kwargs)
                gemini_key_manager.track_usage(key_id)
                return response
            except Exception as exc:
                if self._is_rate_limit(exc) and attempt < max_retries - 1:
                    logger.warning(f"[GeminiKeyRotator] Rate limit on {key_id}. Rotating...")
                    gemini_key_manager.mark_key_failure(key_id)
                    self._stats["total_rotations"] += 1
                    continue
                self._stats["total_errors"] += 1
                raise

    # ------------------------------------------------------------------
    async def generate_content_async(
        self,
        model_name: str,
        prompt,
        endpoint: str = "unknown",
        session_id: Optional[str] = None,
        **kwargs,
    ):
        """
        Async generate_content_async with automatic key rotation via GeminiKeyManager.
        """
        self._stats["total_calls"] += 1
        max_retries = gemini_key_manager.get_key_count() or 1
        
        for attempt in range(max_retries):
            key_info = gemini_key_manager.get_next_key()
            if not key_info:
                raise Exception("All Gemini keys are rate-limited or unavailable.")
            
            key_id = key_info["id"]
            api_key = key_info["key"]
            
            try:
                genai.configure(api_key=api_key)
                model = genai.GenerativeModel(model_name)
                response = await model.generate_content_async(prompt, **kwargs)
                gemini_key_manager.track_usage(key_id)
                return response
            except Exception as exc:
                if self._is_rate_limit(exc) and attempt < max_retries - 1:
                    logger.warning(f"[GeminiKeyRotator] Rate limit on {key_id}. Rotating...")
                    gemini_key_manager.mark_key_failure(key_id)
                    self._stats["total_rotations"] += 1
                    await asyncio.sleep(0.5)
                    continue
                self._stats["total_errors"] += 1
                raise

    # ------------------------------------------------------------------
    def get_stats(self) -> dict:
        with self._lock:
            return dict(self._stats)

    def current_key_index(self) -> int:
        return self._index + 1  # 1-based for human display

    def key_count(self) -> int:
        return gemini_key_manager.get_key_count()


# Module-level singleton – import and use directly
gemini_rotator = GeminiKeyRotator()


# ---------------------------------------------------------------------------
# Batch Translation Helper
# ---------------------------------------------------------------------------

_LANGUAGE_NAMES = {
    "en": "English", "te": "Telugu", "hi": "Hindi", "ta": "Tamil",
    "kn": "Kannada", "ml": "Malayalam", "mr": "Marathi", "gu": "Gujarati",
    "bn": "Bengali", "pa": "Punjabi", "ur": "Urdu", "or": "Odia",
    "as": "Assamese", "mai": "Maithili", "sa": "Sanskrit", "ne": "Nepali",
    "sd": "Sindhi", "ks": "Kashmiri", "kok": "Konkani", "doi": "Dogri",
    "mni": "Manipuri", "brx": "Bodo", "sat": "Santali",
}

_TRANSLATE_MODEL = "gemini-flash-latest"


async def batch_translate_fields(
    fields: dict[str, str],
    target_lang_code: str,
    for_async: bool = True,
    model_name: str = _TRANSLATE_MODEL,
) -> dict[str, str]:
    """
    Translate all complaint fields in a SINGLE Gemini call.
    Default behavior is async; set for_async=False for sync callers.
    """
    if not fields or not target_lang_code:
        return fields

    lang_code = target_lang_code.lower().split("-")[0]
    target_lang_name = _LANGUAGE_NAMES.get(lang_code, "")

    # Skip if English (or unknown → fall back to English)
    if not target_lang_name or target_lang_name == "English":
        return fields

    # Filter out empty values to reduce token count
    non_empty = {k: v for k, v in fields.items() if v and str(v).strip()}
    if not non_empty:
        return fields

    # Deduplicate: some fields may be identical
    value_to_keys: dict[str, list[str]] = {}
    for k, v in non_empty.items():
        value_to_keys.setdefault(v, []).append(k)

    unique_fields = {keys[0]: val for val, keys in value_to_keys.items()}

    prompt = (
        f"Translate the following JSON field values into {target_lang_name}.\n"
        "Rules:\n"
        "- Preserve personal names, phone numbers, places, and legal section references exactly.\n"
        "- Return ONLY a valid JSON object with the same keys as input.\n"
        "- No markdown fences, no explanations, no extra keys.\n\n"
        f"Input JSON:\n{json.dumps(unique_fields, ensure_ascii=False)}"
    )

    try:
        config = genai.types.GenerationConfig(
            temperature=0.1,
            max_output_tokens=1024,
            response_mime_type="application/json",
        )
        session_id = f"translate-{int(time.time())}"
        if for_async:
            response = await gemini_rotator.generate_content_async(
                model_name, 
                prompt, 
                endpoint="batch_translation",
                session_id=session_id,
                generation_config=config
            )
        else:
            response = gemini_rotator.generate_content(
                model_name, 
                prompt, 
                endpoint="batch_translation",
                session_id=session_id,
                generation_config=config
            )
        translated_unique: dict = json.loads(response.text)
    except Exception as exc:
        logger.warning(f"[batch_translate_fields] Failed: {exc}. Returning originals.")
        return fields

    # Expand deduplicated results back to all original keys
    result = dict(fields)
    for val, key_list in value_to_keys.items():
        representative = key_list[0]
        translated_val = translated_unique.get(representative, val)
        for k in key_list:
            result[k] = translated_val

    return result
