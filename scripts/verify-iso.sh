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

echo 'ZEN-OS ISO verifier'
echo '==================='
echo "ISO: $ISO"
file "$ISO"
sha256sum "$ISO"
size=$(stat -c%s "$ISO")
[ "$size" -gt 1000000000 ] || { echo 'ERROR: ISO is unexpectedly small.' >&2; exit 1; }

echo
echo '[1/4] Checking ISO filesystem and boot payload...'
xorriso -indev "$ISO" -find / -maxdepth 2 -type f -print > "$tmp/iso-files.txt" 2>/dev/null
for required in /live/filesystem.squashfs; do
  grep -Fxq "$required" "$tmp/iso-files.txt" || { echo "ERROR: missing $required"; exit 1; }
done
grep -Eq '^/boot/grub/|^/EFI/' "$tmp/iso-files.txt" || { echo 'ERROR: no GRUB/EFI boot payload found'; exit 1; }
echo '  Boot payload: OK'

echo
echo '[2/4] Extracting package manifest when present...'
manifest=''
for candidate in /live/filesystem.packages /live/filesystem.packages-remove; do
  if grep -Fxq "$candidate" "$tmp/iso-files.txt"; then
    xorriso -osirrox on -indev "$ISO" -extract "$candidate" "$tmp/$(basename "$candidate")" >/dev/null 2>&1 || true
    [ -s "$tmp/$(basename "$candidate")" ] && manifest="$tmp/$(basename "$candidate")" && break
  fi
done
if [ -n "$manifest" ]; then
  for pkg in plasma-desktop firefox-esr network-manager ufw apparmor flatpak wine; do
    grep -Eq "^${pkg}([[:space:]]|:)" "$manifest" || echo "WARN: package manifest does not list $pkg"
  done
  echo '  Package manifest: inspected'
else
  echo '  WARN: package manifest not present in ISO; squashfs checks will still run.'
fi

echo
echo '[3/4] Inspecting squashfs contents...'
xorriso -osirrox on -indev "$ISO" -extract /live/filesystem.squashfs "$tmp/filesystem.squashfs" >/dev/null 2>&1
unsquashfs -ll "$tmp/filesystem.squashfs" > "$tmp/squashfs-files.txt"
for required in \
  'usr/local/lib/zenos/control-center.sh' \
  'usr/local/lib/zenos/security.sh' \
  'usr/local/lib/zenos/doctor.sh' \
  'usr/local/lib/zenos/update-center.sh' \
  'usr/share/applications/zenos-control-center.desktop' \
  'usr/share/applications/zenos-doctor.desktop' \
  'etc/os-release'; do
  grep -Fq "$required" "$tmp/squashfs-files.txt" || { echo "ERROR: squashfs missing $required"; exit 1; }
done
echo '  ZEN-OS tools and identity: OK'

echo
echo '[4/4] Checking ISO branding...'
xorriso -indev "$ISO" -pvd_info 2>/dev/null | grep -E 'Volume id|Application id|Publisher id' || true

echo
echo 'ISO static verification PASSED.'
echo 'Note: this proves image structure/content, not GPU/driver behavior on every physical machine.'
