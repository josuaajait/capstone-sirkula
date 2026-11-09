"""Sajikan hasil `flutter build web` untuk preview.

Port diambil dari variabel lingkungan PORT (diisi otomatis oleh preview),
atau 8765 jika tidak ada.
"""

import functools
import http.server
import os
import pathlib
import sys

root = pathlib.Path(__file__).resolve().parent.parent / "build" / "web"
if not (root / "index.html").exists():
    sys.exit(f"{root} belum ada. Jalankan dulu: flutter build web")

port = int(os.environ.get("PORT", "8765"))
handler = functools.partial(http.server.SimpleHTTPRequestHandler, directory=str(root))
with http.server.ThreadingHTTPServer(("127.0.0.1", port), handler) as server:
    print(f"Sirkula web: http://localhost:{port}", flush=True)
    server.serve_forever()
