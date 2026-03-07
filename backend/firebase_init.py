import firebase_admin
from firebase_admin import credentials, firestore
import os
from pathlib import Path

# Paths are relative to the backend directory
cred_filename = "dharma-cms-5cc89-b74e10595572.json"
cred_path = Path(__file__).parent / cred_filename

if not firebase_admin._apps:
    if cred_path.exists():
        cred = credentials.Certificate(str(cred_path))
        firebase_admin.initialize_app(cred)
        print(f"Firebase Admin initialized with {cred_filename}")
    else:
        # Fallback for environments with GOOGLE_APPLICATION_CREDENTIALS
        firebase_admin.initialize_app()
        print("Firebase Admin initialized with default credentials")

db = firestore.client()
