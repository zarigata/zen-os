# Security Policy

## Supported Versions

| Version | Supported |
| ------- | ---------- |
| v1.0.x | Yes |
| Development builds | Best effort |

## Security Architecture

ZEN-OS implements a pragmatic security posture:

- **AppArmor**: Enabled with enforced profiles for system services
- **UFW Firewall**: Default deny incoming, allow outgoing. SSH rate-limited.
- **Unattended Upgrades**: Automatic security updates from Debian security
- **SSH Hardening**: Root login disabled, host keys regenerated on first boot
- **Kernel Hardening**: `kptr_restrict`, `dmesg_restrict`, SYN cookies enabled
- **Secure Boot**: Optional — MOK enrollment wizard available post-install

## Reporting a Vulnerability

**Do not report security vulnerabilities through public GitHub issues.**

Instead, please report them via:

1. **GitHub Security Advisories** (preferred): [Report a vulnerability](https://github.com/zen-os/zen-os/security/advisories/new)
2. **Email**: security@zen-os.org

### What to Include

- Type of vulnerability (privilege escalation, information disclosure, etc.)
- Affected component (kernel, package, configuration, script)
- Step-by-step reproduction instructions
- Potential impact
- Suggested fix (if available)

### Response Timeline

- **Acknowledgment**: Within 48 hours
- **Initial assessment**: Within 7 days
- **Fix or mitigation**: Depends on severity
  - Critical: Priority patch
  - High: Next build cycle
  - Medium/Low: Scheduled fix

### Responsible Disclosure

We ask that you:

1. Give us reasonable time to address the vulnerability before public disclosure
2. Avoid accessing or modifying other users' data
3. Act in good faith to protect users' privacy and security

We commit to:

1. Acknowledging your report promptly
2. Keeping you informed of our progress
3. Crediting you in the fix announcement (unless you prefer anonymity)

## Security Configuration

### What's Hardened

- Root account locked, user gets sudo
- UFW deny-all incoming by default
- SSH: no root login, rate-limited authentication
- AppArmor profiles for Steam, Wine, Docker, PipeWire
- Kernel pointer restriction, dmesg restriction
- Core dumps disabled

### What's Intentionally Relaxed

- Live user has no password (by design — live session)
- Flatpak is available (sandboxed, but broad access)
- Docker group membership (required for development use case)
- Secure Boot disabled by default (gaming kernel compatibility)

These trade-offs are deliberate for a gaming/engineering desktop. If you're using ZEN-OS in a security-sensitive environment, review and tighten these defaults.
