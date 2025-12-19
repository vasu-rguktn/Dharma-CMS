
import sys
import os

# Ensure backend directory is in python path
sys.path.append(r"c:\Users\MYPC\Desktop\intern\Dharma-CMS\backend")

from fastapi import FastAPI
from fastapi.routing import APIRoute

try:
    from main import app
    print("Successfully imported app.")
except ImportError as e:
    print(f"Failed to import app: {e}")
    sys.exit(1)

print("\n=== Active Routes ===")
for route in app.routes:
    if isinstance(route, APIRoute):
        print(f"path='{route.path}' name='{route.name}' methods={route.methods}")
print("=====================\n")
