#!/usr/bin/env python3
"""Secure local HTTP server for KataGo WASM browser build.

Requires Cross-Origin-Opener-Policy and Cross-Origin-Embedder-Policy
headers for WebAssembly threads to function in the browser.
"""

import argparse
import http.server
import mimetypes
from pathlib import Path
import ssl
import sys

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
    parser = argparse.ArgumentParser()
    parser.add_argument("--host", default="127.0.0.1")
    parser.add_argument("--port", type=int, default=8080)
    parser.add_argument("--cert")
    parser.add_argument("--key")
    args = parser.parse_args()
    if bool(args.cert) != bool(args.key):
        parser.error("--cert and --key must be specified together")

    mimetypes.add_type("text/javascript", ".js")
    server = http.server.ThreadingHTTPServer((args.host, args.port), Handler)
    scheme = "http"
    if args.cert:
        context = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
        context.load_cert_chain(args.cert, args.key)
        server.socket = context.wrap_socket(server.socket, server_side=True)
        scheme = "https"

    print(f"KataGo WASM server: {scheme}://{args.host}:{args.port}/", flush=True)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\nShutting down.", flush=True)
        server.server_close()
