#!/usr/bin/env python3
import socket, time

def attempt_login(serial_sock_path="/tmp/zenos-test-serial.sock"):
    s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    s.connect(serial_sock_path)
    s.settimeout(15)
    
    s.send(b"live-user\r")
    time.sleep(2)
    
    try:
        prompt = s.recv(4096)
        print(f"Prompt: {prompt.decode('utf-8', errors='ignore').strip()}")
    except:
        print("No prompt received")
    
    s.send(b"\r")
    time.sleep(2)
    
    try:
        result = s.recv(4096)
        print(f"Result: {result.decode('utf-8', errors='ignore').strip()}")
    except:
        print("No result received")
    
    s.close()

if __name__ == "__main__":
    attempt_login()
