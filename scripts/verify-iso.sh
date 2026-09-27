#!/bin/bash
# Validate the finished ZEN-OS ISO before declaring a build successful.
set -euo pipefail

ISO="${1:-live-image-amd64.hybrid.iso}"

fail() {
    echo "ISO VERIFY ERROR: $*" >&2
    exit 1
}

[ -f "$ISO" ] || fail "ISO not found: $ISO"
command -v xorriso >/dev/null 2>&1 || fail "xorriso is required"
command -v unsquashfs >/dev/null 2>&1 || fail "unsquashfs is required"

TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

echo "ZEN-OS: Verifying ISO boot/install artifacts..."

ISO_LIST="$TMPDIR/iso-list.txt"
xorriso -indev "$ISO" -find / -type f -print 2>/dev/null > "$ISO_LIST"

grep -Eq '^/live/vmlinuz' "$ISO_LIST" || fail "no live kernel found under /live"
grep -Eq '^/live/initrd' "$ISO_LIST" || fail "no live initrd found under /live"
grep -q '^/live/filesystem.squashfs$' "$ISO_LIST" || fail "live filesystem.squashfs missing"

# Debian Installer should be present because auto/config requests --debian-installer live.
if ! grep -Eq '^/(install|install\.amd)/' "$ISO_LIST"; then
    fail "Debian Installer payload is missing from the ISO"
fi

# Inspect the generated GRUB configuration. It must come from live-build rather
# than a version-pinned config checked into the repository.
GRUB_CFG="$TMPDIR/grub.cfg"
xorriso -osirrox on -indev "$ISO" -extract /boot/grub/grub.cfg "$GRUB_CFG" >/dev/null 2>&1 \
    || fail "unable to extract generated /boot/grub/grub.cfg"

grep -q 'boot=live' "$GRUB_CFG" || fail "GRUB has no live boot entry"
grep -q 'username=live-user' "$GRUB_CFG" || fail "live-user boot parameter missing"
if grep -q 'console=ttyS0,115200' "$GRUB_CFG"; then
    fail "normal GRUB entry still forces the serial console"
fi
if grep -Eq 'vmlinuz-7\.0\.5-1-liquorix|vmlinuz-6\.12\.86\+deb13' "$GRUB_CFG"; then
    fail "stale hard-coded kernel filename found in GRUB"
fi

# Verify the graphical installer exists inside the live root filesystem.
SQUASH="$TMPDIR/filesystem.squashfs"
xorriso -osirrox on -indev "$ISO" -extract /live/filesystem.squashfs "$SQUASH" >/dev/null 2>&1 \
    || fail "unable to extract live filesystem"
unsquashfs -ll "$SQUASH" 2>/dev/null | grep -q 'usr/share/applications/calamares-install-debian.desktop' \
    || fail "Calamares desktop installer is missing"
unsquashfs -ll "$SQUASH" 2>/dev/null | grep -q 'usr/share/applications/zenos-installer.desktop' \
    || fail "ZEN-OS installer launcher is missing"

echo "ZEN-OS: ISO verification passed."
