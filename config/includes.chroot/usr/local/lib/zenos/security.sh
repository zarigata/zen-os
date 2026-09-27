#!/bin/bash
set -u

ACTION="${1:-menu}"
SELF="/usr/local/lib/zenos/security.sh"

need_root() {
    if [ "${EUID}" -ne 0 ]; then
        if command -v pkexec >/dev/null 2>&1; then
            exec pkexec /bin/bash "$SELF" "$ACTION"
        fi
        echo "This action needs administrator privileges." >&2
        exit 1
    fi
}

status() {
    echo "=== ZEN-OS Security Status ==="
    echo
    if command -v ufw >/dev/null 2>&1; then
        ufw status 2>/dev/null | sed -n '1,8p'
    else
        echo "Firewall: ufw not installed"
    fi
    echo
    if systemctl is-enabled ssh.service >/dev/null 2>&1 || systemctl is-enabled ssh.socket >/dev/null 2>&1; then
        echo "SSH: enabled (key-only policy)"
    else
        echo "SSH: disabled (default)"
    fi
    if systemctl is-active apparmor.service >/dev/null 2>&1; then
        echo "AppArmor: active"
    else
        echo "AppArmor: not active"
    fi
    if systemctl is-enabled apt-daily-upgrade.timer >/dev/null 2>&1; then
        echo "Automatic security updates: enabled"
    else
        echo "Automatic security updates: disabled"
    fi
}

ssh_keys_exist() {
    find /home -maxdepth 3 -type f -path '*/.ssh/authorized_keys' -size +0c -print -quit 2>/dev/null | grep -q .
}

ssh_on() {
    need_root
    if ! ssh_keys_exist; then
        echo "Refusing to enable key-only SSH: no authorized_keys file was found." >&2
        echo "Add a public key to ~/.ssh/authorized_keys, then try again." >&2
        exit 2
    fi
    ssh-keygen -A
    ufw limit 22/tcp comment 'ZEN-OS SSH' >/dev/null
    systemctl enable --now ssh.service 2>/dev/null || systemctl enable --now ssh.socket
    echo "SSH enabled with key-only authentication and UFW rate limiting."
}

ssh_off() {
    need_root
    systemctl disable --now ssh.service 2>/dev/null || true
    systemctl disable --now ssh.socket 2>/dev/null || true
    ufw delete limit 22/tcp >/dev/null 2>&1 || ufw delete allow 22/tcp >/dev/null 2>&1 || true
    echo "SSH disabled and firewall rule removed."
}

kdeconnect_on() {
    need_root
    ufw allow 1714:1764/tcp comment 'KDE Connect' >/dev/null
    ufw allow 1714:1764/udp comment 'KDE Connect' >/dev/null
    echo "KDE Connect firewall rules enabled."
}

kdeconnect_off() {
    need_root
    ufw delete allow 1714:1764/tcp >/dev/null 2>&1 || true
    ufw delete allow 1714:1764/udp >/dev/null 2>&1 || true
    echo "KDE Connect firewall rules removed."
}

updates() {
    need_root
    apt-get update
    unattended-upgrade --dry-run --debug || true
}

menu() {
    while true; do
        clear
        status
        echo
        echo "1) Enable SSH (requires an existing authorized key)"
        echo "2) Disable SSH"
        echo "3) Enable KDE Connect firewall access"
        echo "4) Disable KDE Connect firewall access"
        echo "5) Check pending automatic security upgrades"
        echo "6) Refresh status"
        echo "0) Exit"
        echo
        read -r -p "Select: " choice
        case "$choice" in
            1) ACTION=ssh-on; ssh_on; read -r -p 'Press Enter...' _ ;;
            2) ACTION=ssh-off; ssh_off; read -r -p 'Press Enter...' _ ;;
            3) ACTION=kdeconnect-on; kdeconnect_on; read -r -p 'Press Enter...' _ ;;
            4) ACTION=kdeconnect-off; kdeconnect_off; read -r -p 'Press Enter...' _ ;;
            5) ACTION=updates; updates; read -r -p 'Press Enter...' _ ;;
            6) ;;
            0) exit 0 ;;
            *) echo "Invalid option"; sleep 1 ;;
        esac
    done
}

case "$ACTION" in
    status) status ;;
    ssh-on) ssh_on ;;
    ssh-off) ssh_off ;;
    kdeconnect-on) kdeconnect_on ;;
    kdeconnect-off) kdeconnect_off ;;
    updates) updates ;;
    menu) menu ;;
    *) echo "Usage: $0 {status|menu|ssh-on|ssh-off|kdeconnect-on|kdeconnect-off|updates}"; exit 2 ;;
esac
