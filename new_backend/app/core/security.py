"""
Security middleware — applied globally to every response.

Uses pure ASGI middleware (not BaseHTTPMiddleware) to avoid known deadlocks
with sync dependencies and thread pools.

1. Security headers (X-Content-Type-Options, etc.)
2. Request body size limit (prevents abuse on file uploads)
3. Trusted Host validation in production
"""

from __future__ import annotations

from fastapi import FastAPI
from starlette.middleware.trustedhost import TrustedHostMiddleware
from starlette.types import ASGIApp, Receive, Scope, Send

from app.core.config import settings


class SecurityHeadersMiddleware:
    """Pure ASGI middleware — adds standard security headers to every HTTP response."""

    def __init__(self, app: ASGIApp) -> None:
        self.app = app

    async def __call__(self, scope: Scope, receive: Receive, send: Send) -> None:
        if scope["type"] != "http":
            await self.app(scope, receive, send)
            return

        async def send_with_headers(message):
            if message["type"] == "http.response.start":
                extra = [
                    (b"x-content-type-options", b"nosniff"),
                    (b"x-frame-options", b"DENY"),
                    (b"x-xss-protection", b"1; mode=block"),
                    (b"referrer-policy", b"strict-origin-when-cross-origin"),
                    (b"permissions-policy", b"geolocation=(), camera=(), microphone=()"),
                ]
                if settings.is_production:
                    extra.append(
                        (b"strict-transport-security", b"max-age=63072000; includeSubDomains; preload")
                    )
                message["headers"] = list(message.get("headers", [])) + extra
            await send(message)

        await self.app(scope, receive, send_with_headers)


class RequestSizeLimitMiddleware:
    """Pure ASGI middleware — rejects requests with Content-Length over the limit."""

    def __init__(self, app: ASGIApp, max_size_mb: int = 10) -> None:
        self.app = app
        self.max_bytes = max_size_mb * 1024 * 1024

    async def __call__(self, scope: Scope, receive: Receive, send: Send) -> None:
        if scope["type"] != "http":
            await self.app(scope, receive, send)
            return

        headers = dict(scope.get("headers", []))
        content_length = headers.get(b"content-length")
        if content_length and int(content_length) > self.max_bytes:
            response_body = (
                b'{"detail":"Request body too large. Max '
                + str(self.max_bytes // (1024 * 1024)).encode()
                + b' MB."}'
            )
            await send({
                "type": "http.response.start",
                "status": 413,
                "headers": [
                    (b"content-type", b"application/json"),
                    (b"content-length", str(len(response_body)).encode()),
                ],
            })
            await send({
                "type": "http.response.body",
                "body": response_body,
            })
            return

        await self.app(scope, receive, send)


def register_security_middleware(app: FastAPI) -> None:
    """Register all security middleware on the app."""
    # Order matters: outermost runs first

    # 1. Trusted hosts (production only)
    if settings.is_production and settings.ALLOWED_HOSTS != ["*"]:
        app.add_middleware(TrustedHostMiddleware, allowed_hosts=settings.ALLOWED_HOSTS)

    # 2. Security headers (pure ASGI — no deadlocks)
    app.add_middleware(SecurityHeadersMiddleware)

    # 3. Request size limit (pure ASGI — no deadlocks)
    app.add_middleware(RequestSizeLimitMiddleware, max_size_mb=settings.MAX_UPLOAD_SIZE_MB)
