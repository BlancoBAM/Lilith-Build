#!/usr/bin/env python3
"""
Lilith Linux Static File Server
Serves Lilith Linux build files to be downloaded inside chroot

Usage:
    python3 serve_lilith.py

Files will be served at http://localhost:8080
"""

import http.server
import socketserver
import os
import sys
from pathlib import Path

PORT = 8080
DIRECTORY = Path(__file__).parent.resolve()

class LilithHandler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=str(DIRECTORY), **kwargs)
    
    def log_message(self, format, *args):
        print(f"[Lilith Server] {args[0]}")

def main():
    os.chdir(DIRECTORY)
    
    with socketserver.TCPServer(("", PORT), LilithHandler) as httpd:
        print(f"""
╔═══════════════════════════════════════════════════════════╗
║         Lilith Linux Static File Server                 ║
╠═══════════════════════════════════════════════════════════╣
║  Serving files from: {DIRECTORY}
║  Access at:       http://localhost:{PORT}
║  From chroot:     http://YOUR_HOST_IP:{PORT}
╚═══════════════════════════════════════════════════════════╝
""")
        
        # Get host IP
        import socket
        try:
            s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
            s.connect(("8.8.8.8", 80))
            host_ip = s.getsockname()[0]
            print(f"  From other machines: http://{host_ip}:{PORT}")
        except:
            pass
        
        print("\nPress Ctrl+C to stop\n")
        
        try:
            httpd.serve_forever()
        except KeyboardInterrupt:
            print("\nServer stopped.")
            sys.exit(0)

if __name__ == "__main__":
    main()
