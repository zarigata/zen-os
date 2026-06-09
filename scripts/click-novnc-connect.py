#!/usr/bin/env python3
import socket
import json
import time

ws_url = "localhost:9222"
page_id = "86A0DB96CB88504305A0B43F7E07A112"

def send_cmd(sock, cmd):
    cmd_json = json.dumps(cmd)
    # WebSocket text frame
    frame = bytearray()
    frame.append(0x81)  # FIN=1, opcode=text
    length = len(cmd_json)
    frame.append(length)
    frame.extend(cmd_json.encode())
    sock.send(frame)

def recv_resp(sock):
    sock.settimeout(5)
    data = sock.recv(4096)
    if not data:
        return None
    # Parse websocket frame
    if len(data) < 2:
        return None
    opcode = data[0] & 0x0f
    if opcode == 1:
        payload_len = data[1]
        return json.loads(data[2:2+payload_len])
    return None

def connect_and_click():
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    s.connect(("localhost", 9222))
    
    # Send handshake
    handshake = f"""GET /devtools/page/{page_id} HTTP/1.1\r\nHost: localhost:9222\r\nConnection: Upgrade\r\nUpgrade: websocket\r\nSec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==\r\nSec-WebSocket-Version: 13\r\n\r\n"""
    s.send(handshake.encode())
    s.settimeout(5)
    resp = s.recv(1024)
    
    if b"101" not in resp:
        print(f"Handshake failed: {resp[:100]}")
        s.close()
        return
    
    # Click the connect button
    click_cmd = {
        "id": 1,
        "method": "Runtime.evaluate",
        "params": {
            "expression": "document.querySelector('#noVNC_connect_button')?.click() || 'no button found'"
        }
    }
    send_cmd(s, click_cmd)
    time.sleep(0.5)
    resp = recv_resp(s)
    print(f"Click response: {json.dumps(resp, indent=2) if resp else 'None'}")
    
    # Check page title
    title_cmd = {
        "id": 2,
        "method": "Runtime.evaluate",
        "params": {
            "expression": "document.title"
        }
    }
    send_cmd(s, title_cmd)
    time.sleep(0.5)
    resp = recv_resp(s)
    print(f"Title: {json.dumps(resp, indent=2) if resp else 'None'}")
    
    # Check if VNC is connected
    status_cmd = {
        "id": 3,
        "method": "Runtime.evaluate",
        "params": {
            "expression": "document.querySelector('#noVNC_status')?.textContent || 'no status'"
        }
    }
    send_cmd(s, status_cmd)
    time.sleep(0.5)
    resp = recv_resp(s)
    print(f"Status: {json.dumps(resp, indent=2) if resp else 'None'}")
    
    s.close()

if __name__ == "__main__":
    connect_and_click()
