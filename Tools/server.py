#!/usr/bin/env python3
"""
Simple HTTP server for prompt-builder deployment
"""

import os
import subprocess
import json
from http.server import HTTPServer, BaseHTTPRequestHandler
from urllib.parse import urlparse, parse_qs
import threading
import time

class DeployHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        """Handle GET requests"""
        parsed_url = urlparse(self.path)
        path = parsed_url.path
        
        if path == '/':
            # Serve the deploy button HTML
            self.send_response(200)
            self.send_header('Content-type', 'text/html')
            self.end_headers()
            
            with open('deploy-button.html', 'r', encoding='utf-8') as f:
                self.wfile.write(f.read().encode('utf-8'))
                
        elif path == '/deploy-button.html':
            # Serve the deploy button HTML
            self.send_response(200)
            self.send_header('Content-type', 'text/html')
            self.end_headers()
            
            with open('deploy-button.html', 'r', encoding='utf-8') as f:
                self.wfile.write(f.read().encode('utf-8'))
                
        elif path == '/prompt-builder.html':
            # Serve the main prompt builder
            self.send_response(200)
            self.send_header('Content-type', 'text/html')
            self.end_headers()
            
            with open('prompt-builder.html', 'r', encoding='utf-8') as f:
                self.wfile.write(f.read().encode('utf-8'))
                
        else:
            self.send_response(404)
            self.end_headers()
            self.wfile.write(b'Not Found')

    def do_POST(self):
        """Handle POST requests for script execution"""
        parsed_url = urlparse(self.path)
        path = parsed_url.path
        
        if path == '/run-script':
            # Parse query parameters
            query_params = parse_qs(parsed_url.query)
            script = query_params.get('script', [''])[0]
            action = query_params.get('action', [''])[0]
            
            # Validate parameters
            if not script or not action:
                self.send_response(400)
                self.send_header('Content-type', 'text/plain')
                self.end_headers()
                self.wfile.write(b'Missing script or action parameter')
                return
            
            # Execute script
            try:
                result = self.run_script(script, action)
                self.send_response(200)
                self.send_header('Content-type', 'text/plain')
                self.send_header('Access-Control-Allow-Origin', '*')
                self.end_headers()
                self.wfile.write(result.encode('utf-8'))
                
            except Exception as e:
                self.send_response(500)
                self.send_header('Content-type', 'text/plain')
                self.send_header('Access-Control-Allow-Origin', '*')
                self.end_headers()
                self.wfile.write(f'Error: {str(e)}'.encode('utf-8'))
                
        else:
            self.send_response(404)
            self.end_headers()
            self.wfile.write(b'Not Found')

    def run_script(self, script, action):
        """Run a bash script with the specified action"""
        script_path = os.path.join(os.getcwd(), script)
        
        if not os.path.exists(script_path):
            raise FileNotFoundError(f"Script not found: {script_path}")
        
        # Make script executable
        os.chmod(script_path, 0o755)
        
        # Run the script
        try:
            result = subprocess.run(
                [script_path, action],
                capture_output=True,
                text=True,
                cwd=os.getcwd(),
                timeout=60  # 60 second timeout
            )
            
            if result.returncode == 0:
                return f"Success: {result.stdout}"
            else:
                return f"Error: {result.stderr}"
                
        except subprocess.TimeoutExpired:
            return "Error: Script execution timed out"
        except Exception as e:
            return f"Error: {str(e)}"

    def log_message(self, format, *args):
        """Custom logging to avoid cluttering the console"""
        pass

def start_server(port=8000):
    """Start the HTTP server"""
    server_address = ('', port)
    httpd = HTTPServer(server_address, DeployHandler)
    
    print(f"🚀 Deploy server started on http://localhost:{port}")
    print(f"📁 Deploy button: http://localhost:{port}/deploy-button.html")
    print(f"🔧 Prompt builder: http://localhost:{port}/prompt-builder.html")
    print(f"⏹️  Press Ctrl+C to stop")
    print()
    
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        print("\n⏹️  Server stopped")
        httpd.server_close()

if __name__ == '__main__':
    start_server() 