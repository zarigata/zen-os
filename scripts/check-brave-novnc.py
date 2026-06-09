#!/usr/bin/env python3
import urllib.request
import json
import time

# Get the websocket URL
debugs_url = "http://localhost:9222/json"
try:
    with urllib.request.urlopen(debugs_url, timeout=5) as resp:
        data = json.loads(resp.read().decode())
        for page in data:
            if "vnc.html" in page.get("url", ""):
                ws_url = page.get("webSocketDebuggerUrl")
                print(f"Found noVNC page: {ws_url}")
                
                # Use websocket to send commands
                import socket
                from urllib.parse import urlparse
                
                parsed = urlparse(ws_url)
                ws_path = parsed.path
                
                # Connect to the websocket
                s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
                s.connect((parsed.hostname, parsed.port))
                
                # Send WebSocket handshake
                handshake = f"""GET {ws_path} HTTP/1.1\r
Host: localhost:{parsed.port}\r
Connection: Upgrade\r
Upgrade: websocket\r
Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==\r
Sec-WebSocket-Version: 13\r
\r
"""
                s.send(handshake.encode())
                s.settimeout(5)
                
                try:
                    resp = s.recv(1024)
                    print(f"Handshake response: {resp[:100]}")
                    
                    # Send Runtime.evaluate to get page title
                    # WebSocket frame format: FIN=1, opcode=1 (text), MASK=0
                    # This is a simplified approach - just try to send JSON
                    cmd = json.dumps({"id": 1, "method": "Runtime.evaluate", "params": {"expression": "document.title"}})
                    # Construct websocket text frame
                    frame = bytearray()
                    frame.append(0x81)  # FIN=1, opcode=text
                    length = len(cmd)
                    frame.append(length)
                    frame.extend(cmd.encode())
                    s.send(frame)
                    time.sleep(1)
                    resp = s.recv(4096)
                    print(f"Response: {resp}")
                except Exception as e:
                    print(f"WebSocket error: {e}")
                
                s.close()
                break
        else:
            print("noVNC page not found in tabs")
            print("Available tabs:")
            for p in data:
                print(f"  - {p.get('title')}: {p.get('url', 'N/A')[:80]}")
except Exception as e:
    print(f"Error: {e}")
