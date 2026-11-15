#!/usr/bin/env python3
"""Serve the LumenFlow character-card generator and open it in a browser."""

from __future__ import annotations

import argparse
import functools
import http.server
import sys
import webbrowser
from pathlib import Path

HOST = "127.0.0.1"
DEFAULT_PORT = 5050
MAX_PORT = 5059
GENERATOR_DIR = Path(__file__).resolve().parent / "assets" / "gen"


class GeneratorRequestHandler(http.server.SimpleHTTPRequestHandler):
    extensions_map = {
        **http.server.SimpleHTTPRequestHandler.extensions_map,
        ".html": "text/html; charset=utf-8",
        ".css": "text/css; charset=utf-8",
        ".js": "application/javascript; charset=utf-8",
        ".json": "application/json; charset=utf-8",
        ".svg": "image/svg+xml; charset=utf-8",
        ".woff2": "font/woff2",
    }

    def end_headers(self) -> None:
        self.send_header("Cache-Control", "no-store, max-age=0")
        self.send_header("X-Content-Type-Options", "nosniff")
        super().end_headers()

    def log_message(self, format: str, *args: object) -> None:
        # Keep the launcher console clean; failures still surface as HTTP errors.
        pass


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--port",
        type=int,
        default=None,
        help="Port to bind (default: first free port from 5050 to 5059)",
    )
    parser.add_argument(
        "--no-open",
        action="store_true",
        help="Start the server without opening a browser",
    )
    return parser.parse_args()


def bind_server(port: int | None) -> http.server.ThreadingHTTPServer:
    candidates = range(DEFAULT_PORT, MAX_PORT + 1) if port is None else (port,)
    handler = functools.partial(
        GeneratorRequestHandler,
        directory=str(GENERATOR_DIR),
    )
    last_error: OSError | None = None
    for candidate in candidates:
        try:
            return http.server.ThreadingHTTPServer((HOST, candidate), handler)
        except OSError as error:
            last_error = error
    raise SystemExit(
        f"Cannot bind a local port"
        f"{'' if port is not None else f' in {DEFAULT_PORT}-{MAX_PORT}'}: "
        f"{last_error}"
    )


def main() -> int:
    args = parse_args()
    if args.port is not None and not 0 <= args.port <= 65535:
        print(f"Invalid port: {args.port}", file=sys.stderr)
        return 2
    if not (GENERATOR_DIR / "index.html").is_file():
        print(f"Generator not found: {GENERATOR_DIR}", file=sys.stderr)
        return 1

    server = bind_server(args.port)
    url = f"http://{HOST}:{server.server_address[1]}/"
    print(f"LumenFlow generator: {url}", flush=True)
    print(f"Serving {GENERATOR_DIR}", flush=True)
    print("Press Ctrl+C to stop.", flush=True)

    if not args.no_open:
        try:
            if not webbrowser.open(url, new=2):
                print(f"Open this URL in your browser: {url}", flush=True)
        except Exception as error:  # pragma: no cover - depends on the desktop.
            print(
                f"Could not open the browser automatically: {error}",
                flush=True,
            )
            print(f"Open this URL in your browser: {url}", flush=True)

    try:
        server.serve_forever(poll_interval=0.25)
    except KeyboardInterrupt:
        print("\nStopped.", flush=True)
    finally:
        server.server_close()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
