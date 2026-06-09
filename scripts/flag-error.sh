#!/bin/bash
# ZEN-OS Error Flagging Tool
# Capture VM state (screenshot + serial log) when user sees an error
# Usage: ./flag-error.sh "error description"

set -e

QEMU_NAME="${ZENOS_NAME:-zenos-test}"
REPORT_DIR="${ZENOS_REPORT_DIR:-/tmp/zenos-reports}"
VNC_PORT="${ZENOS_VNC_PORT:-5900}"
SERIAL_LOG="/tmp/${QEMU_NAME}-serial.log"

mkdir -p "$REPORT_DIR"

DESCRIPTION="${1:-No description provided}"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
REPORT_ID="zenos-error-${TIMESTAMP}"
REPORT_PATH="${REPORT_DIR}/${REPORT_ID}"
mkdir -p "$REPORT_PATH"

echo "=== ZEN-OS Error Report: ${REPORT_ID} ==="

# Capture screenshot via vncdotool
if command -v vncdo >/dev/null 2>&1 && nc -z localhost "$VNC_PORT" 2>/dev/null; then
    vncdo -s "localhost:${VNC_PORT}" capture "${REPORT_PATH}/screenshot.png" 2>/dev/null || true
    echo "Screenshot: ${REPORT_PATH}/screenshot.png"
else
    echo "WARNING: Could not capture screenshot (vncdo not available or VNC not running)"
fi

# Copy serial log
cp "$SERIAL_LOG" "${REPORT_PATH}/serial.log" 2>/dev/null || echo "Serial log not found"

# Copy QEMU args if available
if [ -f "/tmp/${QEMU_NAME}-args.txt" ]; then
    cp "/tmp/${QEMU_NAME}-args.txt" "${REPORT_PATH}/qemu-args.txt"
fi

# Write report metadata
cat > "${REPORT_PATH}/report.json" <<EOF
{
  "id": "${REPORT_ID}",
  "timestamp": "$(date -Iseconds)",
  "description": "${DESCRIPTION}",
    "iso": "$(ls -lh live-image-amd64.hybrid.iso 2>/dev/null || echo 'not found')",
  "screenshot": "${REPORT_PATH}/screenshot.png",
  "serial_log": "${REPORT_PATH}/serial.log",
  "vm_name": "${QEMU_NAME}"
}
EOF

echo ""
echo "Report saved to: ${REPORT_PATH}"
echo ""
echo "To share with the agent:"
echo "  cat ${REPORT_PATH}/report.json"
echo ""
echo "Or simply describe:"
echo "  \"Error: ${DESCRIPTION}\""
echo "  \"Screenshot at ${REPORT_PATH}/screenshot.png\""
