#!/usr/bin/env python3
import socket
import time
import select

def send_receive(sock, data, timeout_sec=3):
    if data:
        sock.send(data.encode('utf-8') if isinstance(data, str) else data)
        time.sleep(0.5)
    
    response = b""
    start_time = time.time()
    while time.time() - start_time < timeout_sec:
        ready = select.select([sock], [], [], 0.1)
        if ready[0]:
            try:
                chunk = sock.recv(4096)
                if not chunk:
                    break
                response += chunk
            except:
                break
    return response.decode('utf-8', errors='ignore')

sock = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
try:
    sock.connect('/tmp/zenos-final-serial.sock')
    sock.settimeout(15)
except Exception as e:
    print(f"Failed to connect: {e}")
    exit(1)

print("Waiting for prompt...")
time.sleep(2)
prompt = send_receive(sock, "")
print(f"Prompt: {prompt}")

if "login" not in prompt.lower():
    print("Retrying...")
    time.sleep(3)
    prompt = send_receive(sock, "\n")
    print(f"Prompt 2: {prompt}")

if "login" in prompt.lower():
    print("Logging in...")
    send_receive(sock, "live-user\n")
    time.sleep(1)
    password_prompt = send_receive(sock, "")
    print(f"Password Prompt: {password_prompt[-50:]}")
    
    send_receive(sock, "\n")
    time.sleep(2)
    
    shell_check = send_receive(sock, "whoami")
    print(f"Shell check: {shell_check}")
    
    if "live-user" in shell_check:
        print("LOGIN SUCCESS")
        commands = [
            "systemctl status sddm --no-pager -n 15",
            "dmesg | grep -iE 'virtio|vga|drm|fb' | tail -30",
            "cat /var/log/Xorg.0.log 2>/dev/null | tail -20",
            "ps aux | grep -E 'Xorg|sddm|plasma|kwin|startplasma' | grep -v grep"
        ]
        for cmd in commands:
            print(f"\n>>> {cmd}")
            send_receive(sock, cmd + "\n")
            time.sleep(1.5)
            result = send_receive(sock, "", timeout_sec=5)
            if result.strip():
                print(result[-1000:])
    else:
        print("Login might have failed")
else:
    print("Did not find login prompt")

sock.close()
