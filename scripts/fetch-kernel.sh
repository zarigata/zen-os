#!/bin/bash
# Download Liquorix kernel packages for the build
# These are too large for GitHub (>100MB) so they're fetched at build time
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
PKG_DIR="${PROJECT_DIR}/config/packages.chroot"

# Liquorix kernel version
KERNEL_VERSION="7.2.7-1"
KERNEL_RELEASE="7.2-12.2~trixie"
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
    tmp="${target}.part"
    rm -f "$tmp"
    if ! curl -fL --retry 3 --retry-delay 2 "${LIQUORIX_REPO}/${pkg}" -o "$tmp"; then
        rm -f "$tmp"
        echo "ERROR: Failed to download required Liquorix package: ${pkg}" >&2
        echo "       Update KERNEL_VERSION/KERNEL_RELEASE if Liquorix has rotated the Trixie packages." >&2
        exit 1
    fi
    mv "$tmp" "$target"
done

echo "ZEN-OS: Kernel packages ready."
ls -lh "$PKG_DIR"/*.deb 2>/dev/null || echo "  WARNING: No .deb packages found"
