"""
SPA-aware static file server for Flutter web builds.
Falls back to index.html for any path that doesn't match a real file.

Usage:  python spa_server.py <build_dir> <port>
"""
import http.server, os, sys, functools

class SPAHandler(http.server.SimpleHTTPRequestHandler):
    def do_GET(self):
        path = self.translate_path(self.path)
        if os.path.exists(path) and not os.path.isdir(path):
            return super().do_GET()
        if os.path.isdir(path) and os.path.exists(os.path.join(path, "index.html")):
            return super().do_GET()
        self.path = "/index.html"
        return super().do_GET()

    def end_headers(self):
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Cache-Control", "no-cache")
        super().end_headers()

    def log_message(self, fmt, *args):
        pass  # quiet

if len(sys.argv) < 3:
    print("Usage: python spa_server.py <build_dir> <port>")
    sys.exit(1)

build_dir = os.path.abspath(sys.argv[1])
port = int(sys.argv[2])

if not os.path.isdir(build_dir):
    print(f"ERROR: {build_dir} not found"); sys.exit(1)
if not os.path.exists(os.path.join(build_dir, "index.html")):
    print(f"ERROR: {build_dir}/index.html missing"); sys.exit(1)

handler = functools.partial(SPAHandler, directory=build_dir)
srv = http.server.HTTPServer(("0.0.0.0", port), handler)
print(f"Serving {build_dir} on http://localhost:{port}  (SPA fallback ON)", flush=True)
srv.serve_forever()
