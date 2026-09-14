import json
import os
import socket
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer


REDIS_HOST = os.getenv("REDIS_HOST", "redis")
REDIS_PORT = int(os.getenv("REDIS_PORT", "6379"))
APP_PORT = int(os.getenv("APP_PORT", "5000"))


def redis_ping():
    payload = b"*1\r\n$4\r\nPING\r\n"
    with socket.create_connection((REDIS_HOST, REDIS_PORT), timeout=2) as connection:
        connection.sendall(payload)
        response = connection.recv(64)
    if not response.startswith(b"+PONG"):
        raise RuntimeError(f"Unexpected Redis response: {response!r}")
    return "PONG"


class Handler(BaseHTTPRequestHandler):
    def send_json(self, status_code, payload):
        body = json.dumps(payload, ensure_ascii=False).encode("utf-8")
        self.send_response(status_code)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self):
        if self.path not in ("/health", "/api/info"):
            self.send_json(404, {"error": "not found"})
            return

        try:
            redis_status = redis_ping()
            self.send_json(
                200,
                {
                    "status": "healthy",
                    "api_container": socket.gethostname(),
                    "redis_service": f"{REDIS_HOST}:{REDIS_PORT}",
                    "redis_response": redis_status,
                },
            )
        except Exception as error:
            self.send_json(503, {"status": "unhealthy", "error": str(error)})

    def log_message(self, message_format, *args):
        print(f"{self.client_address[0]} - {message_format % args}", flush=True)


if __name__ == "__main__":
    server = ThreadingHTTPServer(("0.0.0.0", APP_PORT), Handler)
    print(f"API listening on 0.0.0.0:{APP_PORT}", flush=True)
    server.serve_forever()
