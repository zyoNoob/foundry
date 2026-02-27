import os
from http.server import HTTPServer, BaseHTTPRequestHandler
import urllib.request
import urllib.error

PORT_HEALTH = int(os.environ.get("PORT_HEALTH", "8081"))
LLAMA_PORT = int(os.environ.get("PORT", "8080"))

class HealthHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == "/ping":
            try:
                req = urllib.request.Request(f"http://localhost:{LLAMA_PORT}/health")
                with urllib.request.urlopen(req, timeout=2) as response:
                    if response.status == 200:
                        self.send_response(200)
                        self.end_headers()
                        self.wfile.write(b"OK")
                        return
            except Exception:
                pass
            
            self.send_response(204)
            self.end_headers()
        else:
            self.send_response(404)
            self.end_headers()

    def log_message(self, format, *args):
        pass

if __name__ == "__main__":
    print(f"[foundry] RunPod health sidecar starting on port {PORT_HEALTH}")
    server = HTTPServer(("0.0.0.0", PORT_HEALTH), HealthHandler)
    server.serve_forever()
