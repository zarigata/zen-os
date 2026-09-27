# Security Policy

## Supported Builds

| Build | Support |
| --- | --- |
| Latest release | Security fixes and best-effort support |
| Development branch | Best effort |
| Old ISOs | Update or rebuild before reporting package vulnerabilities |

ZEN-OS follows Debian Trixie security updates. Users should keep automatic security updates enabled and periodically install normal package updates as well.

## Default Security Model

ZEN-OS aims for secure desktop defaults without breaking gaming, Flatpak, browsers or engineering tools:

- **UFW** is enabled with **deny incoming / allow outgoing**.
- **SSH is installed but disabled by default**. When enabled through ZEN-OS Security Center it uses key-only authentication and a rate-limited firewall rule.
- **KDE Connect inbound ports are opt-in** instead of being exposed on every installation.
- **AppArmor** is enabled and its installed profiles are enforced where available.
- **Automatic Debian security updates** are enabled with `unattended-upgrades`.
- **Debian fallback-kernel security updates are allowed**; only the separately pinned Liquorix packages are excluded from unattended replacement.
- **Root login is locked**; administrative actions use sudo or polkit.
- Kernel/network hardening includes ASLR, restricted kernel pointers and dmesg, SYN cookies, redirect/source-route rejection, protected links/FIFOs and conservative ptrace restrictions.
- NetworkManager uses randomized Wi-Fi scan addresses and stable per-network Wi-Fi MAC addresses by default.

These are desktop defaults, not a claim that ZEN-OS is a hardened server distribution.

## Reporting a Vulnerability

Please do **not** publish exploitable security details in a normal GitHub issue.

Use GitHub's private vulnerability reporting / Security Advisory flow for this repository:

https://github.com/zarigata/zen-os/security/advisories/new

Include the affected ZEN-OS version or commit, component, reproduction steps, impact, and any proposed mitigation. For ordinary non-sensitive bugs, use the public issue tracker.

## Security-Sensitive Trade-offs

- Steam, Wine/Proton, Docker/Podman, virtualization and development tooling intentionally increase attack surface compared with a minimal desktop.
- Flatpak is available, but individual application sandbox permissions still matter.
- Liquorix is a third-party performance kernel and is updated deliberately by the ZEN-OS build rather than silently replaced by unattended upgrades.
- Remote access and local-network integration are opt-in because convenience services should not open inbound ports automatically.

Run **ZEN-OS Security Center** from the application menu to review the current firewall/AppArmor/update state and explicitly enable or disable supported network features.
