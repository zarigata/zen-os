# ZEN-OS User Guide

## First boot

ZEN-OS starts with conservative security defaults. The welcome flow offers optional Flathub setup and KDE Connect firewall access. Remote SSH access remains disabled until explicitly enabled.

## Control Center

Open **ZEN-OS Control Center** from the KDE application menu.

Available sections include:

- System Doctor & Diagnostics
- Update Center
- Security & Network
- Performance Profiles
- Game Hub
- Software Center
- Hardware Information
- KDE System Settings

## ZEN-OS Doctor

Run from the application menu or terminal:

```bash
/usr/local/lib/zenos/doctor.sh quick
```

Save a support report:

```bash
/usr/local/lib/zenos/doctor.sh report
```

The report checks storage, memory, core services, firewall/security state, Vulkan, gaming tools, desktop applications, firmware visibility and package health. It intentionally avoids collecting browser history, passwords, SSH private keys, documents or other personal files.

## Updating the system

Open **ZEN-OS Update Center**, or use standard Debian tools.

```bash
sudo apt update
sudo apt full-upgrade
```

Flatpak:

```bash
flatpak update --user
```

Firmware on supported devices:

```bash
fwupdmgr get-updates
```

Automatic Debian security updates are enabled separately through `unattended-upgrades`.

## Security Center

ZEN-OS blocks unsolicited inbound connections by default.

SSH is opt-in. Before enabling it, place your public key in:

```
~/.ssh/authorized_keys
```

Then use **ZEN-OS Security Center** to enable SSH. The ZEN-OS SSH policy disables password login.

KDE Connect is also opt-in at the firewall level.

## Gaming

Steam, Wine, DXVK, MangoHud, GameMode and vkBasalt are part of the intended gaming stack.

Useful checks:

```bash
vulkaninfo --summary
wine --version
gamemoded -t
```

For Steam games that support GameMode, a common launch option is:

```
gamemoderun %command%
```

Hardware and anti-cheat compatibility still depends on the individual game.

## Engineering and development

The image is designed to include CAD/EDA/scientific and development tooling such as FreeCAD, KiCad, OpenSCAD, GNU Radio, Octave, Jupyter, compilers, container tools and virtualization utilities.

If an expected tool is missing on a development build, run ZEN-OS Doctor and report the exact build/commit.

## Software installation

Use KDE Discover for graphical package/Flatpak management. Flathub is optional and is added per-user by the welcome flow when chosen.

For Debian packages:

```bash
sudo apt install PACKAGE
```

## Troubleshooting

Start with:

```bash
/usr/local/lib/zenos/doctor.sh report
systemctl --failed
journalctl -b -p warning
```

For graphics:

```bash
lspci -k | grep -EA3 'VGA|3D|Display'
vulkaninfo --summary
```

For networking:

```bash
nmcli general status
sudo ufw status verbose
```

For package problems:

```bash
sudo dpkg --audit
sudo apt --fix-broken install
```

## Reporting a bug

Open an issue at the project repository and include:

- exact ZEN-OS version or Git commit
- CPU/GPU/model of the machine
- whether the problem occurs in live mode, installed mode, or both
- steps to reproduce
- ZEN-OS Doctor report
- relevant journal output

Do not post passwords, tokens, SSH private keys or other secrets.
