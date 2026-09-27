#!/bin/bash
set -euo pipefail

ISO="${1:-live-image-amd64.hybrid.iso}"
[ -f "$ISO" ] || { echo "ERROR: ISO not found: $ISO" >&2; exit 2; }

sha256sum "$ISO" > "${ISO}.sha256"
sha512sum "$ISO" > "${ISO}.sha512"

echo "Release checksums written:"
echo "  ${ISO}.sha256"
echo "  ${ISO}.sha512"
