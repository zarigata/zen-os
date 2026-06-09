#!/bin/bash
set -e

# ZEN-OS build script — runs inside Docker container or directly on Debian host

BUILD_START=$(date +%s)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_DIR"

echo "=========================================="
echo "   ZEN-OS Build System"
echo "=========================================="
echo "Project dir: $PROJECT_DIR"
echo "Started at:  $(date)"
echo ""

# Step 0: Fetch large packages (kernel .deb too large for GitHub)
echo "[0/3] Fetching kernel packages..."
bash "${SCRIPT_DIR}/fetch-kernel.sh"

# Step 1: Clean previous build
echo "[1/3] Cleaning previous build..."
lb clean --purge 2>/dev/null || true

# Step 2: Configure
echo "[2/3] Running lb config..."
lb config

# Step 3: Build
echo "[3/3] Running lb build (this takes 15-45 minutes)..."
BUILD_LOG="build-$(date +%Y%m%d-%H%M%S).log"
lb build 2>&1 | tee "$BUILD_LOG"
EXIT_CODE=${PIPESTATUS[0]}

BUILD_END=$(date +%s)
BUILD_DURATION=$((BUILD_END - BUILD_START))
MINUTES=$((BUILD_DURATION / 60))
SECONDS=$((BUILD_DURATION % 60))

echo ""
echo "=========================================="
if [ $EXIT_CODE -eq 0 ]; then
    ISO_FILE=$(ls -t live-image-*.hybrid.iso 2>/dev/null | head -1)
    if [ -n "$ISO_FILE" ]; then
        ISO_SIZE=$(du -h "$ISO_FILE" | cut -f1)
        echo "  BUILD SUCCESS"
        echo "  ISO: $ISO_FILE ($ISO_SIZE)"
    else
        echo "  BUILD SUCCESS (no ISO found)"
    fi
else
    echo "  BUILD FAILED (exit code: $EXIT_CODE)"
    echo "  Check: $BUILD_LOG"
fi
echo "  Duration: ${MINUTES}m ${SECONDS}s"
echo "=========================================="

exit $EXIT_CODE
