"""
Application settings loaded from environment / .env file.

SECURITY NOTES:
  - Never commit .env or Firebase credential files to version control.
  - In production, set APP_ENV=production, restrict CORS_ORIGINS, and
    provide a strong SECRET_KEY.
"""

from pydantic_settings import BaseSettings
from pathlib import Path
from typing import List

_project_root = Path(__file__).resolve().parents[2]


class Settings(BaseSettings):
    APP_ENV: str = "development"
    PORT: int = 8000

    # ── Security ──
    SECRET_KEY: str = "CHANGE-ME-in-production-use-openssl-rand-hex-32"
    CORS_ORIGINS: List[str] = ["http://localhost:5555", "http://localhost:5556", "http://localhost:8000"]
    ALLOWED_HOSTS: List[str] = ["*"]

    # ── Database ──
    # Default: local SQLite (zero-install).  Set to a postgresql+asyncpg://
    # connection string for production or Docker usage.
    DATABASE_URL: str = f"sqlite+aiosqlite:///{_project_root / 'dev.db'}"

    # ── Firebase (for token verification only) ──
    # Set to the path of your Firebase service account JSON.
    # Empty = fall back to Application Default Credentials.
    FIREBASE_CREDENTIALS: str = ""

    # ── AI service (old backend) ──
    AI_SERVICE_URL: str = "https://fastapi-app-335340524683.asia-south1.run.app"

    # ── Upload limits ──
    MAX_UPLOAD_SIZE_MB: int = 10

    class Config:
        env_file = _project_root / ".env"
        env_file_encoding = "utf-8"

    @property
    def is_production(self) -> bool:
        return self.APP_ENV == "production"


settings = Settings()
