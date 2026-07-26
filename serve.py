#!/usr/bin/env python3
"""Secure local HTTP server for KataGo WASM browser build.

Requires Cross-Origin-Opener-Policy and Cross-Origin-Embedder-Policy
headers for WebAssembly threads to function in the browser.
"""

import http.server
import mimetypes
from pathlib import Path
import sys

PORT = int(sys.argv[1]) if len(sys.argv) > 1 else 8080
WEB_DIR = Path(__file__).resolve().parent / "web"


class Handler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=str(WEB_DIR), **kwargs)

    def end_headers(self):
        self.send_header("Cross-Origin-Opener-Policy", "same-origin")
        self.send_header("Cross-Origin-Embedder-Policy", "require-corp")
        self.send_header("Cache-Control", "no-cache")
        super().end_headers()

    def log_message(self, format, *args):
        message = format % args
        sys.stderr.write(
            f"{self.address_string()} - - [{self.log_date_time_string()}] {message}\n"
        )


if __name__ == "__main__":
    mimetypes.add_type("text/javascript", ".js")
    server = http.server.ThreadingHTTPServer(("127.0.0.1", PORT), Handler)
    print(f"KataGo WASM server: http://127.0.0.1:{PORT}/", flush=True)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\nShutting down.", flush=True)
        server.server_close()
