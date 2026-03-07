import time
import threading
import asyncio
from typing import Optional, List, Dict, Any
from firebase_admin import firestore
from firebase_init import db
from loguru import logger
import os
from dotenv import load_dotenv

load_dotenv()

class GeminiKeyManager:
    """
    Manages a pool of Gemini API keys from Firestore with:
    - Thread-safe round-robin rotation
    - Automatic 5-minute refresh from Firestore
    - Rate-limit (429) detection and cooldown (60s)
    - Usage tracking in Firestore
    """
    _instance = None
    _lock = threading.Lock()

    def __new__(cls):
        with cls._lock:
            if cls._instance is None:
                cls._instance = super().__new__(cls)
                cls._instance._init_manager()
        return cls._instance

    def _init_manager(self):
        self.keys_pool: List[Dict[str, Any]] = []
        self._current_index = 0
        self._last_refresh_time = 0
        self._refresh_interval_seconds = 300  # 5 minutes
        # Load from .env immediately so we at least have Master keys
        self._load_keys_from_env(self.keys_pool)
        self._last_refresh_time = time.time()
        # Firestore refresh will happen on-demand or after initial startup

    def _load_keys_from_firestore(self):
        """Loads all keys, prioritizing .env (Master) and using Firestore as Fallback."""
        try:
            new_pool = []
            
            # 1. Load from .env (MASTER)
            self._load_keys_from_env(new_pool)
            master_count = len(new_pool)
            
            # 2. Load from Firestore (FALLBACK)
            logger.info("[GeminiKeyManager] Refreshing Fallback keys from Firestore...")
            from google.cloud.firestore_v1.base_query import FieldFilter
            docs = db.collection("gemini_api_keys").where(filter=FieldFilter("status", "==", "active")).stream()
            
            firestore_count = 0
            for doc in docs:
                data = doc.to_dict()
                # Avoid duplicates if the same key is in both .env and Firestore
                if not any(p["key"] == data["key"] for p in new_pool):
                    new_pool.append({
                        "id": f"firestore_{doc.id}",
                        "key": data["key"],
                        "cooldown_until": data.get("cooldown_until", 0),
                        "usage_count": data.get("usage_count", 0)
                    })
                    firestore_count += 1
            
            with self._lock:
                self.keys_pool = new_pool
                self._last_refresh_time = time.time()
                if self._current_index >= len(self.keys_pool):
                    self._current_index = 0
            
            logger.info(f"[GeminiKeyManager] Loaded {len(self.keys_pool)} keys ({master_count} Master from .env, {firestore_count} Fallback from Firestore).")
        except Exception as e:
            logger.error(f"[GeminiKeyManager] Error loading keys: {e}. Ensuring .env keys persist.")
            if not self.keys_pool:
                fallback_pool = []
                self._load_keys_from_env(fallback_pool)
                with self._lock:
                    self.keys_pool = fallback_pool

    def _load_keys_from_env(self, pool: list):
        """Loads keys from GEMINI_API_KEY_N in .env as a master/fallback pool."""
        for i in range(1, 21):
            k = os.getenv(f"GEMINI_API_KEY_{i}", "").strip()
            if k:
                pool.append({
                    "id": f"env_key_{i}",
                    "key": k,
                    "cooldown_until": 0,
                    "usage_count": 0
                })
        
        main_k = os.getenv("GEMINI_API_KEY", "").strip()
        if main_k and not any(p["key"] == main_k for p in pool):
            pool.append({
                "id": "env_key_main",
                "key": main_k,
                "cooldown_until": 0,
                "usage_count": 0
            })

    def _check_refresh_needed(self):
        """Auto-refresh the local cache every 5 minutes."""
        if time.time() - self._last_refresh_time > self._refresh_interval_seconds:
            self._load_keys_from_firestore()

    def get_next_key(self) -> Optional[Dict[str, Any]]:
        """
        Round-robin rotation skipping keys in cooldown.
        Lazy loads Firestore keys if pool only has env keys.
        """
        # If we only have env keys or it's time to refresh, try Firestore
        if not any(k["id"].startswith("firestore_") for k in self.keys_pool) or \
           (time.time() - self._last_refresh_time > self._refresh_interval_seconds):
            # We do a fast check - if it's the very first request, we load Firestore
            # Otherwise we could do this in a thread to avoid blocking the user
            self._load_keys_from_firestore()
        
        with self._lock:
            total_keys = len(self.keys_pool)
            if total_keys == 0:
                return None
            
            now = time.time()
            # Try once through the whole pool
            for _ in range(total_keys):
                candidate = self.keys_pool[self._current_index]
                self._current_index = (self._current_index + 1) % total_keys
                
                # Check cooldown (supports both epoch float and Firestore Timestamp loosely)
                cooldown_until = candidate.get("cooldown_until", 0)
                # If it's a Firestore timestamp, convert to float (duck typing)
                if hasattr(cooldown_until, 'timestamp'):
                    cooldown_until = cooldown_until.timestamp()
                
                if cooldown_until < now:
                    return candidate
            
            return None

    def mark_key_failure(self, key_id: str, cooldown_seconds: int = 60):
        """Marks a key for cooldown in memory and (if applicable) Firestore."""
        cooldown_until = time.time() + cooldown_seconds
        try:
            logger.warning(f"[GeminiKeyManager] Key {key_id} rate-limited. Cooldown for {cooldown_seconds}s.")
            
            # Update Firestore ONLY if it's a Firestore-backed key
            if key_id.startswith("firestore_"):
                actual_doc_id = key_id.replace("firestore_", "")
                db.collection("gemini_api_keys").document(actual_doc_id).update({
                    "cooldown_until": cooldown_until
                })
            
            # Update local memory for immediate effect (applies to both Master and Firestore)
            with self._lock:
                for k in self.keys_pool:
                    if k["id"] == key_id:
                        k["cooldown_until"] = cooldown_until
                        break
        except Exception as e:
            logger.error(f"[GeminiKeyManager] Error marking cooldown for {key_id}: {e}")

    def track_usage(self, key_id: str):
        """Updates usage_count and last_used in Firestore (if applicable)."""
        try:
            # Update local memory count first
            with self._lock:
                for k in self.keys_pool:
                    if k["id"] == key_id:
                        k["usage_count"] = k.get("usage_count", 0) + 1
                        break

            # Update Firestore ONLY if it's a Firestore-backed key
            if key_id.startswith("firestore_"):
                actual_doc_id = key_id.replace("firestore_", "")
                db.collection("gemini_api_keys").document(actual_doc_id).update({
                    "usage_count": firestore.Increment(1),
                    "last_used": firestore.SERVER_TIMESTAMP
                })
        except Exception as e:
            logger.error(f"[GeminiKeyManager] Error tracking usage for {key_id}: {e}")

    def get_key_count(self) -> int:
        """Triggers a lazy refresh to ensure count is accurate for monitoring."""
        if not any(k["id"].startswith("firestore_") for k in self.keys_pool):
            self._load_keys_from_firestore()
        return len(self.keys_pool)

# Singleton instance for the backend
gemini_key_manager = GeminiKeyManager()
