#!/bin/bash
set -u
MODE="${1:-menu}"
SELF="/usr/local/lib/zenos/update-center.sh"

summary(){
  echo 'ZEN-OS Update Center'
  echo '===================='
  echo
  echo 'Debian packages:'
  if command -v apt >/dev/null 2>&1; then
    apt list --upgradable 2>/dev/null | sed '1d' | head -n 20
    count=$(apt list --upgradable 2>/dev/null | sed '1d' | wc -l)
    echo "${count} package update(s) currently visible in the local APT cache."
  fi
  echo
  if command -v flatpak >/dev/null 2>&1; then
    echo 'Flatpak:'
    flatpak remote-ls --updates --columns=application 2>/dev/null | head -n 20 || true
  fi
  echo
  if command -v fwupdmgr >/dev/null 2>&1; then
    echo 'Firmware:'
    fwupdmgr get-updates --no-pager 2>/dev/null | sed -n '1,30p' || echo 'No firmware updates reported (or service unavailable).'
  fi
}

system_update(){
  echo 'Refreshing package metadata...'
  if command -v pkexec >/dev/null 2>&1; then
    pkexec /usr/bin/apt-get update || return 1
    echo
    echo 'The following Debian updates will be installed:'
    apt list --upgradable 2>/dev/null | sed '1d' || true
    echo
    read -r -p 'Continue with Debian full-upgrade? [y/N] ' ans
    [[ "$ans" =~ ^[Yy]$ ]] || return 0
    pkexec /usr/bin/apt-get full-upgrade -y || return 1
  else
    echo 'pkexec is not available; use sudo apt update && sudo apt full-upgrade' >&2
    return 1
  fi
}

flatpak_update(){
  command -v flatpak >/dev/null 2>&1 || { echo 'Flatpak not installed.'; return 0; }
  flatpak update --user
}

firmware_update(){
  command -v fwupdmgr >/dev/null 2>&1 || { echo 'fwupd not installed.'; return 0; }
  fwupdmgr refresh --force || true
  fwupdmgr get-updates --no-pager || true
  echo
  read -r -p 'Install available firmware updates? [y/N] ' ans
  [[ "$ans" =~ ^[Yy]$ ]] || return 0
  fwupdmgr update
}

menu(){
  while true; do
    clear; summary; echo
    echo '1) Refresh + install Debian updates'
    echo '2) Update user Flatpaks'
    echo '3) Check/install firmware updates'
    echo '4) Refresh summary'
    echo '0) Exit'
    read -r -p 'Select: ' choice
    case "$choice" in
      1) system_update; read -r -p 'Press Enter...' _ ;;
      2) flatpak_update; read -r -p 'Press Enter...' _ ;;
      3) firmware_update; read -r -p 'Press Enter...' _ ;;
      4) ;;
      0) exit 0 ;;
      *) sleep 1 ;;
    esac
  done
}

case "$MODE" in summary) summary ;; system) system_update ;; flatpak) flatpak_update ;; firmware) firmware_update ;; menu) menu ;; *) menu ;; esac
