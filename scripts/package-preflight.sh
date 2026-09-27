#!/bin/bash
# Verify that every package requested by package-lists resolves on Debian Trixie.
set -euo pipefail

if [ "$(id -u)" -ne 0 ]; then
  echo 'package-preflight.sh must run as root (normally inside the build container).' >&2
  exit 2
fi

if [ -f /etc/apt/sources.list.d/debian.sources ]; then
  sed -i 's/^Components: .*/Components: main contrib non-free non-free-firmware/' /etc/apt/sources.list.d/debian.sources
fi
apt-get update -qq

mapfile -t packages < <(
  cat config/package-lists/*.list.chroot |
  sed 's/^[[:space:]]*//; s/[[:space:]]*$//' |
  grep -vE '^$|^#' | sort -u
)

echo "Checking ${#packages[@]} unique package names..."
missing=0
for pkg in "${packages[@]}"; do
  if ! apt-cache show "$pkg" >/dev/null 2>&1; then
    echo "MISSING: $pkg"
    missing=$((missing+1))
  fi
done
[ "$missing" -eq 0 ] || { echo "$missing package name(s) unavailable in configured Trixie archives."; exit 1; }

echo 'Simulating combined package install...'
apt-get install --simulate --no-install-recommends "${packages[@]}" >/tmp/zenos-package-sim.log 2>&1 || {
  cat /tmp/zenos-package-sim.log
  exit 1
}
tail -n 25 /tmp/zenos-package-sim.log
echo 'Package preflight passed.'
