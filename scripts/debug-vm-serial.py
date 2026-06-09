#!/usr/bin/env python3
import subprocess
import time
import os
import signal

# Start QEMU with serial to a FIFO
if not os.path.exists('/tmp/vm-serial-in'):
    os.mkfifo('/tmp/vm-serial-in')
if not os.path.exists('/tmp/vm-serial-out'):
    os.mkfifo('/tmp/vm-serial-out')

qemu_cmd = [
    "/usr/bin/qemu-system-x86_64",
    "-enable-kvm", "-smp", "4", "-m", "4096",
    "-drive", "if=pflash,format=raw,readonly=on,file=/usr/share/edk2/ovmf/OVMF_CODE.fd",
    "-drive", "if=pflash,format=raw,file=/tmp/zenos-ovmf-vars.fd",
    "-drive", "file=live-image-amd64.hybrid.iso,media=cdrom,readonly=on",
    "-boot", "d",
    "-netdev", "user,id=net0,hostfwd=tcp::2222-:22",
    "-device", "virtio-net-pci,netdev=net0",
    "-serial", "pipe:/tmp/vm-serial",
    "-display", "none",
    "-name", "zenos-debug"
]

print("Starting QEMU...")
proc = subprocess.Popen(qemu_cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE)

# Wait for boot
print("Waiting 40s for boot...")
time.sleep(40)

# Open FIFOs
print("Opening serial connection...")
ser_out = open('/tmp/vm-serial-out', 'rb')  # QEMU writes here
ser_in = open('/tmp/vm-serial-in', 'wb')    # We write here, QEMU reads

# Read current output
ser_out_fd = os.open('/tmp/vm-serial-out', os.O_RDONLY | os.O_NONBLOCK)
initial = b""
try:
    while True:
        chunk = os.read(ser_out_fd, 4096)
        if not chunk:
            break
        initial += chunk
except:
    pass
os.close(ser_out_fd)

print(f"Initial output: {initial[-500:].decode('utf-8', errors='ignore')}")

if b"login" in initial.lower():
    print("Login prompt found!")
    # Send username
    ser_in.write(b"live-user\r\n")
    ser_in.flush()
    time.sleep(2)
    
    # Read response
    ser_out_fd = os.open('/tmp/vm-serial-out', os.O_RDONLY | os.O_NONBLOCK)
    response = b""
    try:
        while True:
            chunk = os.read(ser_out_fd, 4096)
            if not chunk:
                break
            response += chunk
    except:
        pass
    os.close(ser_out_fd)
    
    print(f"After username: {response[-300:].decode('utf-8', errors='ignore')}")
    
    # Send password (empty for live-user)
    ser_in.write(b"\r\n")
    ser_in.flush()
    time.sleep(2)
    
    # Read login result
    ser_out_fd = os.open('/tmp/vm-serial-out', os.O_RDONLY | os.O_NONBLOCK)
    result = b""
    try:
        while True:
            chunk = os.read(ser_out_fd, 4096)
            if not chunk:
                break
            result += chunk
    except:
        pass
    os.close(ser_out_fd)
    
    print(f"After password: {result[-300:].decode('utf-8', errors='ignore')}")
    
    if b"live-user" in result or b"~" in result:
        print("LOGIN SUCCESS!")
        # Run commands
        commands = [
            "whoami",
            "ls -la /var/log/Xorg*",
            "cat /var/log/Xorg.0.log 2>/dev/null | tail -50",
            "journalctl -u sddm --no-pager -n 20",
            "ps aux | grep -E 'Xorg|sddm|plasma|kwin' | grep -v grep"
        ]
        
        for cmd in commands:
            print(f"\n>>> {cmd}")
            ser_in.write((cmd + "\r\n").encode())
            ser_in.flush()
            time.sleep(2)
            
            ser_out_fd = os.open('/tmp/vm-serial-out', os.O_RDONLY | os.O_NONBLOCK)
            output = b""
            try:
                while True:
                    chunk = os.read(ser_out_fd, 4096)
                    if not chunk:
                        break
                    output += chunk
            except:
                pass
            os.close(ser_out_fd)
            
            print(output[-500:].decode('utf-8', errors='ignore'))
    else:
        print("Login failed or unexpected response")
else:
    print("No login prompt found in serial output")

# Cleanup
ser_in.close()
ser_out.close()
proc.terminate()
proc.wait(timeout=5)
print("\nVM stopped")
