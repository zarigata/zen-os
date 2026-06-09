#!/usr/bin/env python3
import socket
import time

sock = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
sock.connect('/tmp/zenos-test-serial.sock')
sock.settimeout(10)

def read_all(s, timeout=2):
    s.settimeout(timeout)
    data = b""
    try:
        while True:
            chunk = s.recv(4096)
            if not chunk:
                break
            data += chunk
    except:
        pass
    return data.decode('utf-8', errors='ignore')

print("Connected. Waiting for prompt...")
initial = read_all(sock, 3)
print(f"Initial: {initial[-200:]}")

if "login" in initial.lower():
    print("Logging in...")
    sock.send(b"live-user\n")
    time.sleep(1)
    pw = read_all(sock, 2)
    print(f"After user: {pw[-200:]}")

    sock.send(b"\n")
    time.sleep(2)
    result = read_all(sock, 3)
    print(f"After password: {result[-200:]}")

    if "live-user" in result or "~" in result or "$" in result:
        print("LOGIN SUCCESS")
        import subprocess
        import sys

        commands = [
            "whoami",
            "ps aux | grep -E 'Xorg|sddm|plasma|kwin|startplasma' | grep -v grep",
            "systemctl status sddm --no-pager -n 10",
            "ls /usr/share/sddm/themes/",
            "cat /etc/sddm.conf.d/autologin.conf",
            "dmesg | grep -iE 'virtio|vga|drm|fb|modeset' | tail -20",
        ]
        for cmd in commands:
            print(f"\nCMD: {cmd}")
            sock.send((cmd + "\n").encode())
            time.sleep(1.5)
            output = read_all(sock, 4)
            if output.strip():
                print(output[-800:])
    else:
        print("Login failed or unexpected response")
else:
    print("No login prompt found")

sock.close()
