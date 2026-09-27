#!/bin/bash
# ZEN-OS one-time post-install security finalizer
set -euo pipefail

[ "${EUID}" -eq 0 ] || exit 1
mkdir -p /var/lib/zenos

# Keep remote access off until the owner opts in.
systemctl disable --now ssh.service 2>/dev/null || true
systemctl disable --now ssh.socket 2>/dev/null || true

# Reassert the baseline services after installation.
systemctl enable --now apparmor.service 2>/dev/null || true
systemctl enable apt-daily.timer apt-daily-upgrade.timer 2>/dev/null || true
ufw --force enable >/dev/null 2>&1 || true

touch /var/lib/zenos/.first-boot-backend-done
