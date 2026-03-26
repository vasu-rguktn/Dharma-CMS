"""
Minimal SPA-aware static file server for Flutter web builds.
Falls back to index.html for any path that doesn't match a real file
(required for client-side GoRouter / Hash routing).

Usage:
    python serve_flutter.py <build_dir> <port>
"""

import http.server
import os
import sys


class SPAHandler(http.server.SimpleHTTPRequestHandler):
    """Serve files; fall back to index.html for SPA routes."""

    def __init__(self, *args, directory=None, **kwargs):
        super().__init__(*args, directory=directory, **kwargs)

    def do_GET(self):
        # Try the requested path first
        path = self.translate_path(self.path)
        if os.path.exists(path) and not os.path.isdir(path):
            return super().do_GET()
        # If it's a directory and has index.html, serve it
        if os.path.isdir(path):
            index = os.path.join(path, "index.html")
            if os.path.exists(index):
                return super().do_GET()
        # SPA fallback: serve /index.html
        self.path = "/index.html"
        return super().do_GET()

    def end_headers(self):
        # Add CORS headers for local dev
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Cache-Control", "no-cache")
        super().end_headers()

    def log_message(self, format, *args):
        # Quieter logging
        pass


def main():
    if len(sys.argv) < 3:
        print("Usage: python serve_flutter.py <build_dir> <port>")
        sys.exit(1)

    build_dir = os.path.abspath(sys.argv[1])
    port = int(sys.argv[2])

    if not os.path.isdir(build_dir):
        print(f"ERROR: {build_dir} is not a directory")
        sys.exit(1)
    if not os.path.exists(os.path.join(build_dir, "index.html")):
        print(f"ERROR: {build_dir}/index.html not found. Run flutter build web first.")
        sys.exit(1)

    handler = lambda *args, **kw: SPAHandler(*args, directory=build_dir, **kw)
    server = http.server.HTTPServer(("0.0.0.0", port), handler)
    print(f"✅ Serving {build_dir} on http://localhost:{port}")
    print(f"   SPA fallback enabled — all routes → index.html")
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\nShutting down.")
        server.shutdown()


if __name__ == "__main__":
    main()
