"""
Firebase Auth dependency — verifies the ID‑token on every request.

SECURITY:
  - Tokens are verified cryptographically (Firebase Admin SDK checks signature, expiry, issuer).
  - check_revoked=True ensures revoked tokens are immediately rejected.
  - Role-based access is enforced via Firebase custom claims.
"""

from __future__ import annotations

from typing import Annotated, Any, Dict, Optional

from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from firebase_admin import auth

from app.core.firebase import ensure_firebase

_bearer = HTTPBearer(auto_error=True)


class CurrentUser:
    """Lightweight wrapper around the decoded Firebase token."""

    def __init__(self, token: Dict[str, Any]) -> None:
        self._token = token

    @property
    def uid(self) -> str:
        return self._token["uid"]

    @property
    def email(self) -> Optional[str]:
        return self._token.get("email")

    @property
    def phone_number(self) -> Optional[str]:
        return self._token.get("phone_number")

    @property
    def email_verified(self) -> bool:
        return self._token.get("email_verified", False)

    @property
    def role(self) -> Optional[str]:
        """Return custom‑claim role if set, else None."""
        return self._token.get("role")

    @property
    def is_police(self) -> bool:
        return self.role == "police"

    @property
    def is_citizen(self) -> bool:
        return self.role in (None, "citizen")

    @property
    def raw(self) -> Dict[str, Any]:
        return self._token


def get_current_user(
    cred: HTTPAuthorizationCredentials = Depends(_bearer),
) -> CurrentUser:
    """Verify Firebase ID token and return a CurrentUser.

    This is a SYNC function on purpose. FastAPI runs sync dependencies in a
    thread pool, which prevents verify_id_token (also sync, may hit network
    for check_revoked) from blocking the async event loop.
    """
    ensure_firebase()
    token = cred.credentials
    try:
        decoded = auth.verify_id_token(token, check_revoked=True)
    except auth.ExpiredIdTokenError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token has expired. Please sign in again.",
            headers={"WWW-Authenticate": "Bearer"},
        )
    except auth.RevokedIdTokenError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token has been revoked. Please sign in again.",
            headers={"WWW-Authenticate": "Bearer"},
        )
    except auth.InvalidIdTokenError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid authentication token.",
            headers={"WWW-Authenticate": "Bearer"},
        )
    except Exception:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Could not validate credentials.",
            headers={"WWW-Authenticate": "Bearer"},
        )

    return CurrentUser(decoded)


def require_police(user: CurrentUser = Depends(get_current_user)) -> CurrentUser:
    """Dependency that only allows police officers."""
    if not user.is_police:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Police access required.",
        )
    return user


# ── Convenience type aliases for router signatures ──
AuthUser = Annotated[CurrentUser, Depends(get_current_user)]
PoliceUser = Annotated[CurrentUser, Depends(require_police)]
