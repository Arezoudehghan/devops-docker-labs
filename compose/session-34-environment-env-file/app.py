import json
import os
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

PORT = int(os.getenv("APP_PORT", "8000"))


class Handler(BaseHTTPRequestHandler):

    def _send_json(self, status, payload):
        body = json.dumps(
            payload,
            ensure_ascii=False,
            indent=2
        ).encode("utf-8")

        self.send_response(status)
        self.send_header(
            "Content-Type",
            "application/json; charset=utf-8"
        )
        self.send_header(
            "Content-Length",
            str(len(body))
        )
        self.end_headers()

        self.wfile.write(body)

    def do_GET(self):

        if self.path == "/health":
            self._send_json(
                200,
                {"status": "ok"}
            )
            return

        if self.path == "/":
            self._send_json(
                200,
                {
                    "app_name": os.getenv(
                        "APP_NAME",
                        "unset"
                    ),
                    "app_environment": os.getenv(
                        "APP_ENVIRONMENT",
                        "unset"
                    ),
                    "log_level": os.getenv(
                        "LOG_LEVEL",
                        "unset"
                    ),
                    "feature_x": os.getenv(
                        "FEATURE_X",
                        "unset"
                    ),
                    "company": os.getenv(
                        "COMPANY",
                        "unset"
                    ),
                    "app_port": PORT
                }
            )
            return

        self._send_json(
            404,
            {"error": "not found"}
        )

    def log_message(self, format, *args):
        print(
            f"{self.client_address[0]} - "
            f"{format % args}"
        )


if __name__ == "__main__":

    print(
        f"Starting app on 0.0.0.0:{PORT}"
    )

    ThreadingHTTPServer(
        ("0.0.0.0", PORT),
        Handler
    ).serve_forever()
