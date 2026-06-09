#!/bin/bash
# Download Liquorix kernel packages for the build
# These are too large for GitHub (>100MB) so they're fetched at build time
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
PKG_DIR="${PROJECT_DIR}/config/packages.chroot"

# Liquorix kernel version
KERNEL_VERSION="7.0.5-1"
KERNEL_RELEASE="7.0-4.1~trixie"
LIQUORIX_REPO="https://liquorix.net/debian/pool/main/l/linux-liquorix"

mkdir -p "$PKG_DIR"

# List of packages needed
PACKAGES=(
    "linux-image-${KERNEL_VERSION}-liquorix-amd64_${KERNEL_RELEASE}_amd64.deb"
    "linux-headers-${KERNEL_VERSION}-liquorix-amd64_${KERNEL_RELEASE}_amd64.deb"
    "linux-image-liquorix-amd64_${KERNEL_RELEASE}_amd64.deb"
    "linux-headers-liquorix-amd64_${KERNEL_RELEASE}_amd64.deb"
)

echo "ZEN-OS: Fetching Liquorix kernel packages..."

for pkg in "${PACKAGES[@]}"; do
    target="${PKG_DIR}/${pkg}"
    if [ -f "$target" ]; then
        echo "  Already present: ${pkg}"
        continue
    fi
    echo "  Downloading: ${pkg}..."
    curl -fsSL "${LIQUORIX_REPO}/${pkg}" -o "$target" || {
        echo "  WARNING: Failed to download ${pkg}"
        rm -f "$target"
    }
done

echo "ZEN-OS: Kernel packages ready."
ls -lh "$PKG_DIR"/*.deb 2>/dev/null || echo "  WARNING: No .deb packages found"
