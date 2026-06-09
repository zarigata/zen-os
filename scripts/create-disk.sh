#!/bin/bash
set -e

ZENOS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DISK_DIR="${ZENOS_DIR}/disks"
QEMU_NAME="${ZENOS_NAME:-zenos-test}"
DISK_SIZE="${ZENOS_DISK_SIZE:-32G}"

mkdir -p "$DISK_DIR"

DISK_PATH="${DISK_DIR}/${QEMU_NAME}.qcow2"

if [ -f "$DISK_PATH" ]; then
    echo "Disk already exists: ${DISK_PATH}"
    echo "Size: $(qemu-img info "${DISK_PATH}" | grep 'virtual size')"
    echo "Snapshots:"
    qemu-img snapshot -l "${DISK_PATH}" 2>/dev/null || echo "  None"
    exit 0
fi

echo "Creating ${DISK_SIZE} qcow2 disk at ${DISK_PATH}..."
qemu-img create -f qcow2 "${DISK_PATH}" "${DISK_SIZE}"

echo "Disk created."
echo "Path: ${DISK_PATH}"
echo "Use with: -drive file=${DISK_PATH},format=qcow2,if=virtio"
