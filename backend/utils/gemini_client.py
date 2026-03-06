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
        self.keys: list[str] = []
        self.key_tiers: list[str] = []

        # Load numbered keys (up to 20)
        for i in range(1, 21):
            k = os.getenv(f"GEMINI_API_KEY_{i}", "").strip()
            if k:
                self.keys.append(k)
                # Check for tier override, else default to "Free"
                tier = os.getenv(f"GEMINI_TIER_{i}", "Free").strip()
                self.key_tiers.append(tier)

        # Fallback / legacy keys (deduplicated)
        for env_var in ("GEMINI_API_KEY", "GEMINI_API_KEY_INVESTIGATION"):
            k = os.getenv(env_var, "").strip()
            if k and k not in self.keys:
                self.keys.append(k)
                self.key_tiers.append("Free")

        if not self.keys:
            logger.warning("[GeminiKeyRotator] No Gemini API keys found in environment.")

        self._index = 0
        self._stats = {
            "total_calls": 0,
            "total_rotations": 0,
            "total_errors": 0,
            "errors_per_key": {i: 0 for i in range(len(self.keys))},
            "rotations_per_key": {i: 0 for i in range(len(self.keys))},
        }

        logger.info(
            f"[GeminiKeyRotator] Initialized with {len(self.keys)} API key(s). Tiers: {self.key_tiers}"
        )
        if self.keys:
            self._configure(self._index)

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
        Blocking generate_content with automatic key rotation on 429.
        Retries once with the next key before re-raising.
        """
        with self._lock:
            self._stats["total_calls"] += 1
            current_tier = self.key_tiers[self._index] if self._index < len(self.key_tiers) else "Free"
            
        prompt_str = str(prompt)
        call_info = gemini_tracker.log_call(
            model_name, 
            endpoint, 
            len(prompt_str), 
            session_id,
            tier=current_tier
        )

        max_retries = len(self.keys)
        for attempt in range(max_retries):
            try:
                with self._lock:
                    current_idx = self._index
                    current_key_name = f"Key #{current_idx + 1}"
                
                logger.info(f"[GeminiKeyRotator] Attempt {attempt+1}/{max_retries} using {current_key_name}")
                self._configure(current_idx)
                model = genai.GenerativeModel(model_name)
                # Note: model.generate_content is blocking.
                # If calling from async, use generate_content_async.
                response = model.generate_content(prompt, **kwargs)
                gemini_tracker.log_response(call_info, response, session_id)
                return response
            except Exception as exc:
                # If rate limit and we have more keys to try
                if self._is_rate_limit(exc) and attempt < max_retries - 1 and len(self.keys) > 1:
                    logger.warning(f"[GeminiKeyRotator] Rate limit on {current_key_name}. Trying next key...")
                    with self._lock:
                        self._stats["total_errors"] += 1
                        self._stats["errors_per_key"][self._index] = (
                            self._stats["errors_per_key"].get(self._index, 0) + 1
                        )
                    self._rotate()
                    continue  # retry with new key
                with self._lock:
                    self._stats["total_errors"] += 1
                logger.error(f"[GeminiKeyRotator] CRITICAL: Failed after {max_retries} attempts. All keys might be exhausted.")
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
        Async generate_content_async with automatic key rotation on 429.
        Retries once with the next key before re-raising.
        """
        with self._lock:
            self._stats["total_calls"] += 1
            current_tier = self.key_tiers[self._index] if self._index < len(self.key_tiers) else "Free"

        prompt_str = str(prompt)
        call_info = gemini_tracker.log_call(
            model_name, 
            endpoint, 
            len(prompt_str), 
            session_id,
            tier=current_tier
        )

        max_retries = len(self.keys)
        for attempt in range(max_retries):
            try:
                with self._lock:
                    current_idx = self._index
                    current_key_name = f"Key #{current_idx + 1}"
                
                logger.info(f"[GeminiKeyRotator] Attempt {attempt+1}/{max_retries} using {current_key_name}")
                self._configure(current_idx)
                model = genai.GenerativeModel(model_name)
                response = await model.generate_content_async(prompt, **kwargs)
                gemini_tracker.log_response(call_info, response, session_id)
                return response
            except Exception as exc:
                is_rate = self._is_rate_limit(exc)
                if is_rate and attempt < max_retries - 1:
                    logger.warning(f"[GeminiKeyRotator] Rate limit on {current_key_name}. Trying next key...")
                    with self._lock:
                        self._stats["total_errors"] += 1
                        self._stats["errors_per_key"][self._index] = (
                            self._stats["errors_per_key"].get(self._index, 0) + 1
                        )
                    self._rotate()
                    # Small sleep to avoid instant-fail on all keys if it's broad
                    await asyncio.sleep(0.5)
                    continue
                
                with self._lock:
                    self._stats["total_errors"] += 1
                
                if is_rate:
                    logger.error(f"[GeminiKeyRotator] ALL {max_retries} KEYS EXHAUSTED for {model_name}.")
                raise

    # ------------------------------------------------------------------
    def get_stats(self) -> dict:
        with self._lock:
            return dict(self._stats)

    def current_key_index(self) -> int:
        return self._index + 1  # 1-based for human display

    def key_count(self) -> int:
        return len(self.keys)


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
