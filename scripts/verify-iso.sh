#!/bin/bash
# Static health check for a built ZEN-OS ISO.
set -euo pipefail

ISO="${1:-live-image-amd64.hybrid.iso}"
[ -f "$ISO" ] || { echo "ERROR: ISO not found: $ISO" >&2; exit 2; }

for cmd in xorriso unsquashfs sha256sum file; do
  command -v "$cmd" >/dev/null 2>&1 || { echo "ERROR: missing dependency: $cmd" >&2; exit 2; }
done

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

echo "ZEN-OS ISO verifier"
echo "==================="
echo "ISO: $ISO"
file "$ISO"
sha256sum "$ISO"
size=$(stat -c%s "$ISO")
[ "$size" -gt 1000000000 ] || { echo "ERROR: ISO is unexpectedly small." >&2; exit 1; }

echo
echo "[1/4] Checking live filesystem and boot payload..."
xorriso -indev "$ISO" -ls /live > "$tmp/live.txt" 2>/dev/null
grep -q "filesystem.squashfs" "$tmp/live.txt" || { echo "ERROR: /live/filesystem.squashfs is missing"; exit 1; }

boot_ok=0
if xorriso -indev "$ISO" -ls /boot/grub > "$tmp/grub.txt" 2>/dev/null; then
  [ -s "$tmp/grub.txt" ] && boot_ok=1
fi
if [ "$boot_ok" -eq 0 ] && xorriso -indev "$ISO" -ls /EFI > "$tmp/efi.txt" 2>/dev/null; then
  [ -s "$tmp/efi.txt" ] && boot_ok=1
fi
[ "$boot_ok" -eq 1 ] || { echo "ERROR: no GRUB/EFI boot payload found"; exit 1; }
echo "  Live filesystem + boot payload: OK"

echo
echo "[2/4] Inspecting package manifest when present..."
manifest="$tmp/filesystem.packages"
if xorriso -osirrox on -indev "$ISO" -extract /live/filesystem.packages "$manifest" >/dev/null 2>&1 && [ -s "$manifest" ]; then
  for pkg in plasma-desktop firefox-esr network-manager ufw apparmor flatpak wine; do
    grep -Eq "^${pkg}([[:space:]]|:)" "$manifest" || echo "WARN: package manifest does not list $pkg"
  done
  echo "  Package manifest: inspected"
else
  echo "  WARN: /live/filesystem.packages is not present; squashfs checks continue."
fi

echo
echo "[3/4] Inspecting squashfs contents..."
xorriso -osirrox on -indev "$ISO" -extract /live/filesystem.squashfs "$tmp/filesystem.squashfs" >/dev/null 2>&1
unsquashfs -ll "$tmp/filesystem.squashfs" > "$tmp/squashfs-files.txt"

for required in \
  "usr/local/lib/zenos/control-center.sh" \
  "usr/local/lib/zenos/security.sh" \
  "usr/local/lib/zenos/doctor.sh" \
  "usr/local/lib/zenos/update-center.sh" \
  "usr/share/applications/zenos-control-center.desktop" \
  "usr/share/applications/zenos-doctor.desktop" \
  "usr/share/applications/zenos-update-center.desktop" \
  "etc/os-release"; do
  grep -Fq "$required" "$tmp/squashfs-files.txt" || { echo "ERROR: squashfs missing $required"; exit 1; }
done

# Pull the dpkg status database directly from squashfs without unpacking the full rootfs.
if unsquashfs -cat "$tmp/filesystem.squashfs" var/lib/dpkg/status > "$tmp/dpkg-status" 2>/dev/null; then
  for pkg in plasma-desktop firefox-esr network-manager ufw apparmor flatpak; do
    awk -v pkg="$pkg" '
      BEGIN { RS=""; FS="\n"; found=0 }
      $0 ~ ("Package: " pkg "($|\n)") && $0 ~ /Status: install ok installed/ { found=1 }
      END { exit found ? 0 : 1 }
    ' "$tmp/dpkg-status" || { echo "ERROR: $pkg is not recorded as installed in squashfs"; exit 1; }
  done
  echo "  dpkg installed-state checks: OK"
fi

echo "  ZEN-OS tools and identity: OK"

echo
echo "[4/4] Checking ISO branding..."
xorriso -indev "$ISO" -pvd_info 2>/dev/null | grep -E "Volume id|Application id|Publisher id" || true

echo
echo "ISO static verification PASSED."
echo "This validates image structure and contents, not every physical GPU/Wi-Fi/installer path."
