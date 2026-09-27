#!/bin/bash
set -u

ACTION="${1:-menu}"
SELF="/usr/local/lib/zenos/control-center.sh"

security() { konsole -e /bin/bash /usr/local/lib/zenos/security.sh menu >/dev/null 2>&1 & }
doctor() { konsole -e /bin/bash /usr/local/lib/zenos/doctor.sh interactive >/dev/null 2>&1 & }
updates() { konsole -e /bin/bash /usr/local/lib/zenos/update-center.sh menu >/dev/null 2>&1 & }
settings() { systemsettings >/dev/null 2>&1 & }
software() { plasma-discover >/dev/null 2>&1 & }
hardware() { kinfocenter >/dev/null 2>&1 & }
games() {
    if command -v steam >/dev/null 2>&1; then steam >/dev/null 2>&1 &
    else kdialog --error "Steam is not installed correctly. Open Discover or rebuild the image."; fi
}
performance() {
    if ! command -v powerprofilesctl >/dev/null 2>&1; then
        kdialog --error "power-profiles-daemon is not available on this hardware/build."
        return
    fi
    current="$(powerprofilesctl get 2>/dev/null || echo unknown)"
    choice="$(kdialog --title 'ZEN-OS Performance' --menu "Current profile: ${current}" performance 'Performance' balanced 'Balanced' power-saver 'Power Saver' 2>/dev/null || true)"
    [ -n "$choice" ] || return
    powerprofilesctl set "$choice" || kdialog --error "This hardware does not support that profile."
}

menu() {
    choice="$(kdialog --title 'ZEN-OS Control Center' --menu 'Choose a section' doctor 'System Doctor & Diagnostics' updates 'Update Center' security 'Security & Network' performance 'Performance Profiles' games 'Game Hub' software 'Software Center' hardware 'Hardware Information' settings 'KDE System Settings' 2>/dev/null || true)"
    [ -n "$choice" ] || exit 0
    "$choice"
}

case "$ACTION" in
    menu) menu ;;
    security) security ;;
    doctor) doctor ;;
    updates) updates ;;
    performance) performance ;;
    games) games ;;
    software) software ;;
    hardware) hardware ;;
    settings|system) settings ;;
    *) menu ;;
esac
