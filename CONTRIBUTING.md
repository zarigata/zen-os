# Contributing to ZEN-OS

Thank you for your interest in contributing to ZEN-OS! This document covers everything you need to know.

---

## Quick Start

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/my-feature`
3. Make your changes
4. Test your changes: `make build` or at minimum `make test-docker`
5. Commit with a descriptive message
6. Open a Pull Request

---

## Project Structure Conventions

### Package Lists (`config/package-lists/`)

Each file is a curated list of packages, one per line, with comments for sections.

```bash
## Category — Brief Description
package-name
another-package
```

**Rules**:
- One package per line
- Use `##` for section headers
- Packages that require i386 go in `00-multiarch.hook.chroot`, NOT in package lists
- Never add packages that conflict with existing ones (test with `make test-docker`)
- Keep lists focused — one category per file

### Hooks (`config/hooks/live/`)

Hooks are bash scripts that run during the build process inside the chroot.

**Naming convention**: `NN-description.hook.chroot` where `NN` is a two-digit priority number.

| Range | Purpose |
|-------|---------|
| 00-09 | Architecture, repo setup |
| 10-19 | Service enablement |
| 20-29 | System configuration |
| 30-39 | Theming, branding |
| 40-89 | Optional features |
| 90-99 | Cleanup, finalization |

**Rules**:
- Always start with `#!/bin/bash` and `set -e`
- Use `echo "ZEN-OS: Doing X..."` for build log visibility
- Use `|| true` for commands that may fail in Docker but succeed in real builds
- Never modify files owned by live-build itself
- Keep hooks idempotent — safe to run multiple times

### Included Files (`config/includes.chroot/`)

Files placed here are overlaid onto the target filesystem during build. The directory structure mirrors the target system:

```
config/includes.chroot/
├── etc/
│   ├── os-release           # → /etc/os-release
│   ├── sysctl.d/            # → /etc/sysctl.d/
│   └── sddm.conf.d/         # → /etc/sddm.conf.d/
├── usr/
│   ├── share/               # → /usr/share/ (themes, icons, wallpapers)
│   └── local/bin/           # → /usr/local/bin/ (custom scripts)
└── home/                    # → /home/ (default user config)
```

**Rules**:
- Never include secrets, keys, or credentials
- Use proper file permissions (scripts must be executable)
- Prefer hooks over included files for configuration that requires variable substitution

---

## Testing Your Changes

### Mandatory: Docker Package Test

Before submitting any package list or hook changes:

```bash
make test-docker
```

This verifies all packages resolve without conflicts.

### Recommended: Full Build Test

If you changed hooks, includes, or the build configuration:

```bash
make build
```

Then boot the ISO:

```bash
./scripts/test-vm.sh --docker
```

### Smoke Test

```bash
./scripts/smoke-test.sh
```

---

## Commit Messages

Use clear, descriptive commit messages:

```
category: brief description

Optional longer description explaining the why.
```

Examples:
```
packages: add octave-signal and octave-image to sim-native

hooks: fix SDDM session detection for Plasma 6 Wayland

theme: update GRUB theme colors to match ZEN-OS palette

fix: resolve i386 multiarch ordering issue with Steam
```

---

## Areas That Need Help

### High Priority
- **Theme refinement**: GRUB, Plymouth, SDDM, and KDE Plasma theming
- **Handheld testing**: Real Steam Deck / ROG Ally / Legion Go testing
- **Documentation**: User guides, installation instructions

### Medium Priority
- **Translation**: i18n for the first-boot wizard
- **Testing**: Expanding the QEMU test suite
- **Package versioning**: Automated version bump detection

### Nice to Have
- **GNOME edition**: Alternative desktop config (Phase 9)
- **CI/CD**: GitHub Actions for automated builds
- **Custom APT repo**: Hosting custom ZEN-OS packages

---

## Reporting Issues

### Bug Reports

Use the [Bug Report template](https://github.com/zen-os/zen-os/issues/new?template=bug_report.md). Include:

1. ZEN-OS version (from `cat /etc/os-release`)
2. Hardware (GPU, CPU, laptop/desktop/handheld)
3. What you expected to happen
4. What actually happened
5. Relevant logs (`journalctl -b`, `dmesg`, serial output)

### Feature Requests

Use the [Feature Request template](https://github.com/zen-os/zen-os/issues/new?template=feature_request.md). Describe:

1. The use case (who benefits and how)
2. Suggested implementation (if you have ideas)
3. Whether you're willing to help implement it

---

## Code of Conduct

Be respectful. Be constructive. We're all here to make a great OS.

- Use welcoming and inclusive language
- Be respectful of differing viewpoints
- Accept constructive criticism gracefully
- Focus on what's best for the community
- Show empathy toward other community members

---

## License

By contributing to ZEN-OS, you agree that your contributions will be licensed under the [GPL-3.0 License](LICENSE).
