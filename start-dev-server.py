#!/usr/bin/env python3
"""
Development Server for AWS Todo App Frontend
Serves static files with proper MIME types for local development and testing
"""

import http.server
import socketserver
import os
import sys
import webbrowser
from pathlib import Path

# Configuration
PORT = 8000
FRONTEND_DIR = "frontend"

class CustomHTTPRequestHandler(http.server.SimpleHTTPRequestHandler):
    """Custom handler with CORS support and proper MIME types"""
    
    def end_headers(self):
        # Add CORS headers for local development
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type, Authorization')
        super().end_headers()

    def do_OPTIONS(self):
        """Handle preflight CORS requests"""
        self.send_response(200)
        self.end_headers()

    def guess_type(self, path):
        """Enhanced MIME type detection"""
        mimetype, encoding = super().guess_type(path)
        
        # Ensure JSON files are served with correct MIME type
        if path.endswith('.json'):
            return 'application/json', encoding
        elif path.endswith('.js'):
            return 'application/javascript', encoding
        elif path.endswith('.css'):
            return 'text/css', encoding
        
        return mimetype, encoding

def main():
    """Start the development server"""
    # Change to frontend directory
    if not os.path.exists(FRONTEND_DIR):
        print(f"❌ Error: {FRONTEND_DIR} directory not found!")
        print("Please run this script from the project root directory.")
        sys.exit(1)
    
    os.chdir(FRONTEND_DIR)
    
    # Check if required files exist
    required_files = ['index.html', 'config.json', 'app-fixed.js']
    missing_files = [f for f in required_files if not os.path.exists(f)]
    
    if missing_files:
        print(f"❌ Error: Missing required files: {', '.join(missing_files)}")
        sys.exit(1)
    
    print("🚀 Starting AWS Todo App Development Server")
    print("=" * 50)
    print(f"📁 Serving from: {os.getcwd()}")
    print(f"🌐 Server URL: http://localhost:{PORT}")
    print(f"📄 Main page: http://localhost:{PORT}/index.html")
    print()
    print("✅ Files found:")
    for file in required_files:
        size = os.path.getsize(file)
        print(f"  📄 {file} ({size} bytes)")
    
    # Start server
    try:
        with socketserver.TCPServer(("", PORT), CustomHTTPRequestHandler) as httpd:
            print()
            print("🎯 Server ready! Opening browser...")
            print("Press Ctrl+C to stop the server")
            print()
            
            # Open browser automatically
            webbrowser.open(f'http://localhost:{PORT}/index.html')
            
            # Start serving
            httpd.serve_forever()
            
    except KeyboardInterrupt:
        print("\n👋 Server stopped")
    except OSError as e:
        if "Address already in use" in str(e):
            print(f"❌ Port {PORT} is already in use. Try a different port:")
            print(f"   python3 start-dev-server.py {PORT + 1}")
        else:
            print(f"❌ Server error: {e}")

if __name__ == "__main__":
    # Allow custom port as command line argument
    if len(sys.argv) > 1:
        try:
            PORT = int(sys.argv[1])
        except ValueError:
            print("❌ Invalid port number. Using default port 8000.")
    
    main()
