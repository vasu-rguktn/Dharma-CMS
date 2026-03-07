import google.generativeai as genai
from gemini_key_manager import gemini_key_manager
from loguru import logger
import asyncio
from typing import Optional, Any

class GeminiService:
    """
    Service to interact with Gemini API using Firestore-managed keys.
    Implements:
    - Automatic key rotation on 429 errors
    - Retries across the entire key pool
    - Usage tracking in Firestore
    """
    
    async def generate_content_async(self, model_name: str, prompt: str, **kwargs) -> Any:
        """
        Async content generation with automatic rotation on rate limits.
        """
        total_keys = gemini_key_manager.get_key_count()
        if total_keys == 0:
            logger.error("[GeminiService] No active Gemini keys found in Firestore.")
            raise Exception("AI Service Unavailable: No keys configured.")

        # Limit retries to the number of available keys in pool
        for attempt in range(total_keys):
            key_info = gemini_key_manager.get_next_key()
            if not key_info:
                # This means all keys are active but currently in cooldown
                logger.error("[GeminiService] All API keys are currently rate-limited (cooldown).")
                raise Exception("AI Service Unavailable: Rate limits reached. Please try again in 60 seconds.")
            
            key_id = key_info["id"]
            api_key = key_info["key"]
            
            try:
                # Configure SDK for this request
                genai.configure(api_key=api_key)
                model = genai.GenerativeModel(model_name)
                
                # Execute async call
                response = await model.generate_content_async(prompt, **kwargs)
                
                # Check if response actually has content (sometimes it's blocked/empty)
                if not response.text:
                    logger.warning(f"[GeminiService] Empty response text from key {key_id}.")
                
                # Successfully used! Log to Firestore
                gemini_key_manager.track_usage(key_id)
                return response
                
            except Exception as e:
                error_msg = str(e).lower()
                # 429 Detection
                if "429" in error_msg or "resourceexhausted" in error_msg or "quota" in error_msg:
                    logger.warning(f"[GeminiService] Rate limit (429) hit on {key_id}. Marking cooldown and rotating...")
                    gemini_key_manager.mark_key_failure(key_id, cooldown_seconds=60)
                    # Retry with next key automatically
                    continue
                else:
                    # Non-rate-limit errors (e.g. invalid request, 500)
                    logger.error(f"[GeminiService] API Error on {key_id}: {e}")
                    raise Exception(f"AI Generation Error: {str(e)}")

        raise Exception("AI Service Unavailable: Exhausted all available keys due to rate limits.")

    def generate_content_sync(self, model_name: str, prompt: str, **kwargs) -> Any:
        """
        Synchronous wrapper for generate_content if needed.
        """
        # Note: In FastAPI we prefer async, but some legacy scripts might use sync.
        # This can be implemented if required.
        pass

# Instance for standard usage
gemini_service_instance = GeminiService()
