import os
import socket
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

VERSION = os.getenv("APP_VERSION", "unknown")
HEALTH_MODE = os.getenv("HEALTH_MODE", "ok")
HOSTNAME = socket.gethostname()


class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == "/health":
            if HEALTH_MODE == "fail":
                body = b"FAIL\n"
                self.send_response(500)
            else:
                body = b"OK\n"
                self.send_response(200)
        else:
            body = f"VERSION={VERSION} HOST={HOSTNAME}\n".encode()
            self.send_response(200)

        self.send_header("Content-Type", "text/plain; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def log_message(self, format, *args):
        return


server = ThreadingHTTPServer(("0.0.0.0", 8000), Handler)
server.serve_forever()
