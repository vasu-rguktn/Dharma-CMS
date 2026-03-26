"""
Initialise Firebase Admin SDK for **token verification only**.

PostgreSQL is the data store — Firestore is NOT used.

SECURITY:
  - The service account JSON is NEVER committed to git.
  - Set FIREBASE_CREDENTIALS in .env to the path or filename.
  - In production (Cloud Run/GCE), Application Default Credentials are used.
"""

import firebase_admin
from firebase_admin import credentials
from pathlib import Path
from .config import settings

_firebase_ready = False


def _init_firebase() -> bool:
    """Initialise the Firebase Admin SDK (idempotent). Returns True if ready."""
    global _firebase_ready
    if firebase_admin._apps:
        _firebase_ready = True
        return True

    # 1. Try explicit credential file
    cred_value = settings.FIREBASE_CREDENTIALS.strip()
    if cred_value:
        cred_path = Path(cred_value)
        if not cred_path.is_absolute():
            cred_path = Path(__file__).resolve().parents[2] / cred_value
        if cred_path.exists():
            cred = credentials.Certificate(str(cred_path))
            firebase_admin.initialize_app(cred)
            print(f"✅ Firebase Admin initialised with {cred_path.name}")
            _firebase_ready = True
            return True

    # 2. Try Application Default Credentials (Cloud Run, GCE, etc.)
    try:
        firebase_admin.initialize_app()
        print("✅ Firebase Admin initialised with default credentials")
        _firebase_ready = True
        return True
    except Exception as e:
        print(f"⚠️  Firebase Admin SDK NOT initialised: {e}")
        print("   Auth endpoints will return 503.")
        print("   Set FIREBASE_CREDENTIALS in .env to a service account JSON path.")
        _firebase_ready = False
        return False


def ensure_firebase() -> None:
    """Raise if Firebase is not initialised. Called lazily from auth."""
    if not _firebase_ready:
        from fastapi import HTTPException, status
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Firebase Admin SDK is not configured. Set FIREBASE_CREDENTIALS and restart.",
        )


_init_firebase()
