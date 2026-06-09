#!/bin/bash
# ZEN-OS Automated Smoke Test Suite
# Runs after VM boots to verify all systems operational

set -e

ZENOS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
QEMU_NAME="${ZENOS_NAME:-zenos-test}"
VNC_DISPLAY="${ZENOS_VNC_DISPLAY:-:0}"
REPORT_DIR="${ZENOS_REPORT_DIR:-/tmp/zenos-smoke-reports}"
REPORT_ID="smoke-$(date +%Y%m%d_%H%M%S)"
REPORT_PATH="${REPORT_DIR}/${REPORT_ID}"
SERIAL_LOG="/tmp/${QEMU_NAME}-serial.log"

PASS=0
FAIL=0
WARN=0

mkdir -p "$REPORT_PATH/screenshots"

pass() { echo "  [PASS] $1"; PASS=$((PASS+1)); }
fail() { echo "  [FAIL] $1"; FAIL=$((FAIL+1)); echo "FAIL: $1" >> "$REPORT_PATH/failures.txt"; }
warn() { echo "  [WARN] $1"; WARN=$((WARN+1)); }

# ============================================
# TEST 1: VM Boots (serial log shows systemd)
# ============================================
test_boot() {
    echo ""
    echo "[TEST 1] Boot Verification"
    if [ ! -f "$SERIAL_LOG" ]; then
        fail "Serial log not found"
        return
    fi
    if strings "$SERIAL_LOG" | grep -q "systemd-logind"; then
        pass "systemd started successfully"
    else
        fail "systemd not detected in serial log"
    fi
    if strings "$SERIAL_LOG" | grep -qi "debian login"; then
        pass "Login prompt reached"
    else
        warn "Login prompt not detected (may still be booting)"
    fi
}

# ============================================
# TEST 2: Display / Desktop (VNC screenshot)
# ============================================
test_desktop() {
    echo ""
    echo "[TEST 2] Desktop Verification"

VNC_HOST="localhost"
VNC_PORT="5900"
VNC_DISPLAY="${ZENOS_VNC_DISPLAY:-:0}"

    # Wait for VNC to be available (up to 60s)
    for i in {1..30}; do
        if nc -z "$VNC_HOST" "$VNC_PORT" 2>/dev/null; then
            break
        fi
        sleep 2
    done

    if ! nc -z "$VNC_HOST" "$VNC_PORT" 2>/dev/null; then
        fail "VNC not available on ${VNC_HOST}:${VNC_PORT}"
        return
    fi

    # Send Enter to trigger auto-login if needed
    vncdo -s "${VNC_HOST}:${VNC_DISPLAY}" key enter 2>/dev/null || true
    sleep 45

    # Capture screenshot
    SCREENSHOT="${REPORT_PATH}/screenshots/desktop.png"
    if vncdo -s "${VNC_HOST}:${VNC_DISPLAY}" capture "$SCREENSHOT" 2>/dev/null; then
        pass "Screenshot captured"
    else
        fail "Could not capture screenshot"
        return
    fi

    # Analyze with Python
    python3 -c "
import sys
from PIL import Image
import numpy as np
img = Image.open('${SCREENSHOT}')
arr = np.array(img)
h, w = arr.shape[:2]
nonblack = (arr.mean(axis=2) > 10).sum()
panel = arr[h-50:h, :]
panel_dark = (panel.mean(axis=2) < 80).sum()
panel_total = panel.shape[0]*panel.shape[1]
teal = ((arr[:,:,1] > 80) & (arr[:,:,2] > 80) & (arr[:,:,0] < 100)).sum()

has_desktop = nonblack > h*w*0.5 and panel_dark/panel_total > 0.5
has_wallpaper = teal > h*w*0.05

print(f'Display: {w}x{h}, brightness: {arr.mean():.1f}')
print(f'Non-black: {100*nonblack/(h*w):.1f}%')
print(f'Teal pixels: {100*teal/(h*w):.1f}%')
print(f'Panel dark: {100*panel_dark/panel_total:.1f}%')

if has_desktop:
    print('DESKTOP_OK')
else:
    print('DESKTOP_FAIL')

if has_wallpaper:
    print('WALLPAPER_OK')
else:
    print('WALLPAPER_FAIL')
" 2>/dev/null | tee "${REPORT_PATH}/desktop-analysis.txt"

    if grep -q "DESKTOP_OK" "${REPORT_PATH}/desktop-analysis.txt"; then
        pass "KDE Plasma desktop detected"
    else
        fail "Desktop not detected"
    fi

    if grep -q "WALLPAPER_OK" "${REPORT_PATH}/desktop-analysis.txt"; then
        pass "ZEN-OS wallpaper present"
    else
        warn "Teal wallpaper not detected"
    fi
}

# ============================================
# TEST 3: Services (from serial log)
# ============================================
test_services() {
    echo ""
    echo "[TEST 3] Service Verification"

    SERVICES=(
        "ufw.service:UFW Firewall"
        "sddm.service:SDDM Display Manager"
        "NetworkManager.service:Network Manager"
        "zenos-first-boot.service:First-Boot Wizard"
    )

    for svc in "${SERVICES[@]}"; do
        svc_name=$(echo "$svc" | cut -d: -f1)
        svc_label=$(echo "$svc" | cut -d: -f2)
        if strings "$SERIAL_LOG" | grep -q "${svc_name}"; then
            pass "${svc_label} started"
        else
            warn "${svc_label} not detected in serial log"
        fi
    done
}

# ============================================
# TEST 4: Network (VM has IP)
# ============================================
test_network() {
    echo ""
    echo "[TEST 4] Network Verification"

    # Check if we can reach VM via forwarded SSH port
    if nc -z localhost 2222 2>/dev/null; then
        pass "VM SSH port reachable (localhost:2222)"
    else
        warn "VM SSH port not yet available (may need more time)"
    fi
}

# ============================================
# TEST 5: ISO Integrity
# ============================================
test_iso() {
    echo ""
    echo "[TEST 5] ISO Verification"

    ISO_PATH="${ZENOS_DIR}/live-image-amd64.hybrid.iso"
    if [ ! -f "$ISO_PATH" ]; then
        fail "ISO not found"
        return
    fi

    ISO_SIZE=$(stat -c%s "$ISO_PATH")
    ISO_SIZE_GB=$(awk "BEGIN {printf \"%.1f\", ${ISO_SIZE}/1024/1024/1024}")
    echo "  ISO: ${ISO_PATH} (${ISO_SIZE_GB} GB)"

    if [ "$ISO_SIZE" -gt 1000000000 ]; then
        pass "ISO size valid (${ISO_SIZE_GB} GB)"
    else
        fail "ISO too small (${ISO_SIZE_GB} GB)"
    fi
}

# ============================================
# RUN ALL TESTS
# ============================================
echo "=========================================="
echo "  ZEN-OS Smoke Test Suite"
echo "  VM: ${QEMU_NAME}"
echo "  Report: ${REPORT_PATH}"
echo "=========================================="

test_iso
test_boot
test_desktop
test_services
test_network

# Summary
echo ""
echo "=========================================="
echo "  Results: ${PASS} passed, ${FAIL} failed, ${WARN} warnings"
echo "=========================================="

# Write JSON report
cat > "${REPORT_PATH}/report.json" << EOF
{
  "id": "${REPORT_ID}",
  "timestamp": "$(date -Iseconds)",
  "vm_name": "${QEMU_NAME}",
  "iso": "${ZENOS_DIR}/live-image-amd64.hybrid.iso",
  "passed": ${PASS},
  "failed": ${FAIL},
  "warnings": ${WARN},
  "screenshots": $(ls "${REPORT_PATH}/screenshots/" 2>/dev/null | wc -l),
  "report_dir": "${REPORT_PATH}"
}
EOF

if [ $FAIL -eq 0 ]; then
    echo "  ALL TESTS PASSED"
    exit 0
else
    echo "  SOME TESTS FAILED — check ${REPORT_PATH}/failures.txt"
    exit 1
fi
