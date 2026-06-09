#!/bin/bash
# ZEN-OS QEMU test launcher
# Usage: ./scripts/qemu-test.sh [iso_path]

ISO="${1:-live-image-amd64.hybrid.iso}"
OVMF_CODE="/usr/share/edk2/ovmf/OVMF_CODE.fd"
OVMF_VARS="/tmp/zenos-ovmf-vars.fd"
SERIAL_LOG="/tmp/zenos-serial.log"
PID_FILE="/tmp/zenos-qemu.pid"
DISK="/tmp/zenos-test-disk.qcow2"

# Cleanup
pkill -f "qemu-system-x86_64.*zenos" 2>/dev/null
sleep 1

# Prepare
cp /usr/share/edk2/ovmf/OVMF_VARS.fd "$OVMF_VARS"
[ -f "$DISK" ] || qemu-img create -f qcow2 "$DISK" 8G
> "$SERIAL_LOG"

# Launch QEMU (UEFI, 2CPU, 2GB RAM, VNC on :0)
qemu-system-x86_64 \
  -enable-kvm \
  -smp 2 \
  -m 2048 \
  -drive if=pflash,format=raw,readonly=on,file="$OVMF_CODE" \
  -drive if=pflash,format=raw,file="$OVMF_VARS" \
  -drive file="$ISO",media=cdrom,readonly=on \
  -drive file="$DISK",format=qcow2,if=virtio \
  -boot d \
  -netdev user,id=net0 \
  -device virtio-net-pci,netdev=net0 \
  -serial file:"$SERIAL_LOG" \
  -display none \
  -vga virtio \
  -vnc :0 \
  -pidfile "$PID_FILE" \
  -no-reboot

echo "QEMU exited with code $?"
