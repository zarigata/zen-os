#!/bin/bash
set -u

MARKER="${HOME}/.config/zenos/first-boot-done"
[ -e "$MARKER" ] && exit 0
mkdir -p "$(dirname "$MARKER")"

if ! command -v kdialog >/dev/null 2>&1; then
    touch "$MARKER"
    exit 0
fi

kdialog --title "Welcome to ZEN-OS" --msgbox "Welcome to ZEN-OS.\n\nThis build starts with a deny-by-default firewall, AppArmor, automatic Debian security updates, and remote services disabled until you choose to enable them.\n\nThe next few prompts let you opt into useful extras."

if kdialog --title "Flathub" --yesno "Add Flathub for a much larger application catalog?\n\nThis is added only for your user account."; then
    if command -v flatpak >/dev/null 2>&1; then
        flatpak remote-add --user --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo || true
    fi
fi

if command -v kdeconnect-cli >/dev/null 2>&1; then
    if kdialog --title "KDE Connect" --yesno "Allow KDE Connect through the firewall so you can pair a phone on your local network?"; then
        pkexec /bin/bash /usr/local/lib/zenos/security.sh kdeconnect-on || true
    fi
fi

if kdialog --title "ZEN-OS Security" --yesno "Open the ZEN-OS Security Center now?"; then
    konsole -e /bin/bash /usr/local/lib/zenos/security.sh menu >/dev/null 2>&1 &
fi

touch "$MARKER"
kdialog --title "ZEN-OS Ready" --passivepopup "ZEN-OS setup complete. Firefox, Discover, Bluetooth, printing and power profiles are ready to use." 6
