#!/bin/bash
set -u

MODE="${1:-interactive}"
REPORT="${2:-${HOME}/zenos-diagnostics-$(date +%Y%m%d-%H%M%S).txt}"
PASS=0; WARN=0; FAIL=0

ok(){ printf '[ OK ] %s\n' "$1"; PASS=$((PASS+1)); }
warn(){ printf '[WARN] %s\n' "$1"; WARN=$((WARN+1)); }
fail(){ printf '[FAIL] %s\n' "$1"; FAIL=$((FAIL+1)); }
have(){ command -v "$1" >/dev/null 2>&1; }

run_checks(){
  echo 'ZEN-OS Doctor'
  echo '============='
  echo "Generated: $(date -Iseconds 2>/dev/null || date)"
  echo
  echo '-- System --'
  if [ -r /etc/os-release ]; then . /etc/os-release; echo "OS: ${PRETTY_NAME:-unknown}"; fi
  echo "Kernel: $(uname -r)"
  echo "Session: ${XDG_SESSION_TYPE:-unknown}"
  echo "Desktop: ${XDG_CURRENT_DESKTOP:-unknown}"
  echo

  echo '-- Storage / memory --'
  df -h / | tail -n1
  free -h | sed -n '1,2p'
  root_use=$(df -P / | awk 'NR==2 {gsub(/%/,"",$5); print $5}')
  [ "${root_use:-100}" -lt 90 ] && ok 'Root filesystem has usable free space' || warn 'Root filesystem is over 90% full'
  echo

  echo '-- Core services --'
  for svc in NetworkManager.service ufw.service apparmor.service; do
    if systemctl is-active --quiet "$svc" 2>/dev/null; then ok "$svc active"; else warn "$svc not active"; fi
  done
  if systemctl is-enabled --quiet apt-daily-upgrade.timer 2>/dev/null; then ok 'Automatic security-update timer enabled'; else warn 'Automatic security-update timer disabled'; fi
  if systemctl is-active --quiet ssh.service 2>/dev/null || systemctl is-active --quiet ssh.socket 2>/dev/null; then warn 'SSH is currently listening; verify this is intentional'; else ok 'SSH is not listening by default'; fi
  echo

  echo '-- Graphics / gaming --'
  if have lspci; then lspci | grep -Ei 'vga|3d|display' || true; fi
  if have vulkaninfo; then
    if vulkaninfo --summary >/tmp/zenos-vulkan.$$ 2>&1; then ok 'Vulkan initializes'; sed -n '1,24p' /tmp/zenos-vulkan.$$; else fail 'Vulkan initialization failed'; cat /tmp/zenos-vulkan.$$; fi
    rm -f /tmp/zenos-vulkan.$$
  else warn 'vulkaninfo not installed'; fi
  have steam && ok 'Steam command present' || warn 'Steam command not present'
  have wine && ok "Wine present: $(wine --version 2>/dev/null || true)" || warn 'Wine command not present'
  if have gamemoded; then ok 'GameMode installed'; else warn 'GameMode daemon not found'; fi
  have mangohud && ok 'MangoHud installed' || warn 'MangoHud command not found'
  echo

  echo '-- Desktop applications --'
  for app in firefox-esr dolphin konsole plasma-discover flatpak; do
    have "$app" && ok "$app available" || warn "$app not found"
  done
  echo

  echo '-- Firmware / hardware --'
  if have fwupdmgr; then fwupdmgr get-devices --no-pager 2>/dev/null | sed -n '1,40p' || warn 'fwupd could not enumerate devices'; else warn 'fwupdmgr not installed'; fi
  echo

  echo '-- Package health --'
  if have dpkg; then
    bad=$(dpkg --audit 2>/dev/null || true)
    if [ -z "$bad" ]; then ok 'dpkg reports no interrupted package state'; else fail 'dpkg reports package issues'; echo "$bad"; fi
  fi
  echo
  echo "Summary: ${PASS} OK, ${WARN} warnings, ${FAIL} failures"
}

case "$MODE" in
  --report|report)
    run_checks | tee "$REPORT"
    echo
    echo "Report saved to: $REPORT"
    ;;
  --quick|quick)
    run_checks
    ;;
  interactive|menu)
    clear
    run_checks
    echo
    read -r -p 'Save this report to your home folder? [y/N] ' ans
    if [[ "$ans" =~ ^[Yy]$ ]]; then run_checks > "$REPORT"; echo "Saved: $REPORT"; fi
    read -r -p 'Press Enter to close...' _
    ;;
  *) echo "Usage: $0 [quick|report] [report-path]"; exit 2 ;;
esac
