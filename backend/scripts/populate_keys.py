import sys
import os
from pathlib import Path
from dotenv import load_dotenv

# Add backend to path so we can import firebase_init
backend_dir = Path(__file__).parent.parent
sys.path.append(str(backend_dir))

from firebase_init import db
from loguru import logger

def add_gemini_key(key_id: str, api_key: str):
    """Adds a single Gemini API key to Firestore."""
    try:
        doc_ref = db.collection("gemini_api_keys").document(key_id)
        doc_ref.set({
            "key": api_key,
            "status": "active",
            "usage_count": 0,
            "cooldown_until": 0,
            "last_used": None
        }, merge=True)
        logger.success(f"Successfully added key: {key_id}")
    except Exception as e:
        logger.error(f"Failed to add key {key_id}: {e}")

if __name__ == "__main__":
    print("--- Gemini API Key Populator from .env ---")
    
    # Load .env explicitly from the backend directory
    env_path = backend_dir / ".env"
    load_dotenv(dotenv_path=env_path, override=True)
    
    keys_to_add = {}
    
    # Collect all GEMINI_API_KEY_X from the environment/dotenv variables
    for key, value in os.environ.items():
        if key.startswith("GEMINI_API_KEY_") and value.strip():
            # Skip keys that might be generic placeholders or empty
            keys_to_add[key] = value.strip()
    
    # Also check the basic GEMINI_API_KEY
    main_key = os.getenv("GEMINI_API_KEY")
    if main_key and main_key.strip():
        keys_to_add["GEMINI_API_KEY_MAIN"] = main_key.strip()

    if not keys_to_add:
        print(f"\n[!] No GEMINI_API_KEY_* variables found in {env_path}.")
        print("Please check your .env file and try again.")
    else:
        print(f"Found {len(keys_to_add)} keys to migrate to Firestore.")
        for alias, key in keys_to_add.items():
            add_gemini_key(alias.lower(), key)
        print("\nMigration Complete!")
