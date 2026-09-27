#!/bin/bash
# Fetch the exact Liquorix kernel artifacts pinned by versions.lock.
# ZEN-OS deliberately does NOT install Liquorix moving meta-packages here:
# a reproducible ISO should contain the exact image/header pair we tested.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
PKG_DIR="${PROJECT_DIR}/config/packages.chroot"

KERNEL_VERSION="7.2.7-1"
KERNEL_RELEASE="7.2-12.2~trixie"
LIQUORIX_REPO="https://liquorix.net/debian/pool/main/l/linux-liquorix"

mkdir -p "$PKG_DIR"

PACKAGES=(
    "linux-image-${KERNEL_VERSION}-liquorix-amd64_${KERNEL_RELEASE}_amd64.deb"
    "linux-headers-${KERNEL_VERSION}-liquorix-amd64_${KERNEL_RELEASE}_amd64.deb"
)

echo "ZEN-OS: Preparing pinned Liquorix ${KERNEL_VERSION} (${KERNEL_RELEASE})..."

# Remove any previously downloaded Liquorix kernel/meta packages. A stale
# linux-image-liquorix-amd64 meta-package can depend on a kernel that has
# disappeared from the upstream pool and break lb chroot_install-packages.
find "$PKG_DIR" -maxdepth 1 -type f \
    \( -name 'linux-image-*liquorix-amd64_*.deb' -o -name 'linux-headers-*liquorix-amd64_*.deb' \) \
    -delete

for pkg in "${PACKAGES[@]}"; do
    target="${PKG_DIR}/${pkg}"
    tmp="${target}.part"

    echo "  Downloading: ${pkg}..."
    rm -f "$tmp"

    if ! curl -fL --retry 3 --retry-delay 2 --connect-timeout 20 \
        "${LIQUORIX_REPO}/${pkg}" -o "$tmp"; then
        rm -f "$tmp"
        echo "ERROR: Failed to download pinned Liquorix package: ${pkg}" >&2
        echo "       Update scripts/fetch-kernel.sh and versions.lock together after testing." >&2
        exit 1
    fi

    [ -s "$tmp" ] || {
        echo "ERROR: Downloaded package is empty: ${pkg}" >&2
        rm -f "$tmp"
        exit 1
    }

    mv "$tmp" "$target"
done

echo "ZEN-OS: Verifying downloaded package metadata..."
for pkg in "${PACKAGES[@]}"; do
    target="${PKG_DIR}/${pkg}"
    if command -v dpkg-deb >/dev/null 2>&1; then
        dpkg-deb --info "$target" >/dev/null || {
            echo "ERROR: Invalid Debian package: ${pkg}" >&2
            exit 1
        }
    fi
done

echo "ZEN-OS: Pinned Liquorix packages ready:"
ls -lh "$PKG_DIR"/*liquorix-amd64_*.deb
