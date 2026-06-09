<p align="center">
  <img src="wallpapers/ChatGPT%20Image%20May%209%2C%202026%2C%2003_46_16%20AM%20(1).png" alt="ZEN-OS Logo" width="180"/>
</p>

<h1 align="center">ZEN-OS</h1>

<p align="center">
  <strong>A Debian-based Linux distribution built for engineering & gaming.</strong>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Base-Debian%20Trixie%20(13)-A80030?style=flat-square&logo=debian" alt="Debian Trixie"/>
  <img src="https://img.shields.io/badge/Desktop-KDE%20Plasma-1D99F3?style=flat-square&logo=kde" alt="KDE Plasma"/>
  <img src="https://img.shields.io/badge/Kernel-Liquorix%207.0-00C853?style=flat-square" alt="Liquorix Kernel"/>
  <img src="https://img.shields.io/badge/Arch-AMD64%20(x86__64)-0078D4?style=flat-square" alt="AMD64"/>
  <img src="https://img.shields.io/badge/License-GPL--3.0-blue?style=flat-square" alt="GPL-3.0"/>
  <img src="https://img.shields.io/badge/Status-Phase%201%20Complete-brightgreen?style=flat-square" alt="Status"/>
</p>

---

## What is ZEN-OS?

ZEN-OS is a custom Debian-based Linux distribution designed from the ground up for two things: **gaming** and **engineering**. Inspired by [Nobara Linux](https://nobara-project.org/), it ships with a gaming-tuned Liquorix kernel, full Vulkan/DXVK/Wine stack, professional engineering tools (CAD, EDA, simulation), and a cohesive custom theme.

No post-install tinkering. Boot it. Game on it. Build on it.

### Design Principles

- **Batteries included** — Gaming stack, engineering tools, codecs, and firmware pre-installed
- **Hardware-agnostic** — AMD, NVIDIA, and Intel GPUs all supported equally
- **Pragmatic security** — AppArmor + UFW + auto-updates. Not a fortress, not a free-for-all
- **Reproducible builds** — Docker-based build pipeline with version-locked packages
- **Handheld-ready** — Steam Deck, ROG Ally, and other handheld gaming PCs supported

---

## Features at a Glance

| Category | What's Included |
|----------|----------------|
| **Desktop** | KDE Plasma with custom ZEN-OS teal theme, SDDM login, Plymouth splash |
| **Kernel** | Liquorix 7.0.5 (gaming-tuned) + Debian 6.12 fallback |
| **GPU Drivers** | AMD (Mesa Vulkan), Intel (ANV), NVIDIA (post-install wizard) |
| **Gaming** | Steam, Wine 10.0, DXVK, MangoHud, GameMode, vkBasalt, Gamescope |
| **Engineering** | FreeCAD, KiCad, OpenSCAD, GNU Radio, Octave, Jupyter, Docker |
| **Audio** | PipeWire + WirePlumber with low-latency gaming profile |
| **Security** | UFW firewall, AppArmor, unattended security upgrades, SSH hardening |
| **First-Boot** | Welcome wizard: hardware detect, NVIDIA driver install, Flatpak app selector |
| **Handheld** | Controller udev rules, Steam Big Picture mode, TDP control scripts |
| **Testing** | Docker package resolution, QEMU boot tests, screenshot analysis, MCP server |

---

## System Requirements

| Component | Minimum | Recommended |
|-----------|---------|-------------|
| CPU | 64-bit x86 (AMD64), dual-core | Quad-core with AVX2 |
| RAM | 4 GB | 8 GB+ |
| Disk | 20 GB for installation | 50 GB+ SSD |
| GPU | Any with Vulkan 1.1 support | AMD Radeon RX 5000+ / NVIDIA GTX 1000+ |
| Boot | UEFI firmware | UEFI with Secure Boot (optional) |

> **Note**: The ISO is approximately 3.4 GB. UEFI boot is required.

---

## Download

See [Releases](https://github.com/zen-os/zen-os/releases) for the latest ISO.

```bash
# Verify the download
sha256sum -c live-image-amd64.hybrid.iso.sha256
```

### Write to USB

```bash
# Linux / macOS
sudo dd if=live-image-amd64.hybrid.iso of=/dev/sdX bs=4M status=progress && sync

# Or with Ventoy — just drop the ISO on the Ventoy drive
```

---

## Build from Source

ZEN-OS uses [live-build](https://live-team.pages.debian.net/live-manual/) to construct the ISO. The entire build runs inside Docker, so it works on any host OS (Debian, Ubuntu, Fedora, macOS).

### Prerequisites

- Docker (with `--privileged` support)
- 15-45 minutes
- ~20 GB free disk space

### Quick Build

```bash
git clone https://github.com/zen-os/zen-os.git
cd zen-os
make build
```

This will:
1. Build the Docker build environment (`zen-os-build:latest`)
2. Run the full live-build pipeline inside the container
3. Produce `live-image-amd64.hybrid.iso`

### Build Without Docker

If you're already on a Debian Trixie host with live-build installed:

```bash
sudo apt install live-build debootstrap squashfs-tools xorriso grub-efi-amd64-bin
make build-native
```

### Make Targets

```bash
make build          # Full build (Docker)
make build-native   # Build without Docker
make clean          # Clean build artifacts
make distclean      # Clean + remove Docker image
make test-all       # Run all test suites
make release        # Generate checksums, split ISO, create torrent
```

---

## Project Structure

```
zen-os/
├── auto/                       # live-build auto/ scripts
│   ├── config                  #   lb config — the nerve center
│   ├── build                   #   lb build wrapper
│   └── clean                   #   lb clean wrapper
├── config/                     # live-build configuration tree
│   ├── archives/               #   APT source lists (WineHQ, Liquorix, ZEN-OS)
│   ├── hooks/                  #   Build hooks (multiarch, security, first-boot)
│   │   ├── live/               #     Chroot hooks (run inside the target system)
│   │   └── normal/             #     Binary hooks (run on the ISO image)
│   ├── includes.chroot/        #   Files overlaid onto the target filesystem
│   │   ├── etc/                #     os-release, sysctl, SDDM config, UFW rules
│   │   ├── usr/                #     Themes, scripts, systemd units
│   │   └── home/               #     Default user config
│   ├── package-lists/          #   Package lists by category
│   └── packages.chroot/        #   Local .deb packages (Liquorix kernel)
├── scripts/                    # Build & test automation
│   ├── build.sh                #   Main build entry point
│   ├── test-vm.sh              #   QEMU VM launcher (web/VNC/MCP modes)
│   ├── smoke-test.sh           #   Automated smoke test suite
│   ├── create-disk.sh          #   Create VM test disk
│   ├── snapshot.sh             #   VM snapshot manager
│   └── flag-error.sh           #   Error report capture
├── mcp-server/                 # MCP server for AI-assisted testing
│   ├── server.py               #   FastMCP server (build, test, release tools)
│   └── requirements.txt
├── tests/                      # Test suites
│   ├── docker/                 #   Package resolution tests
│   ├── qemu/                   #   Boot tests
│   ├── vision/                 #   Screenshot analysis
│   ├── rmc/                    #   Remote management tests
│   └── games/                  #   Gaming stack validation
├── wallpapers/                 # ZEN-OS wallpapers
├── repo/                       # APT repository signing key
├── Dockerfile.build            # Build environment definition
├── Makefile                    # Top-level build orchestration
└── versions.lock               # Pinned package versions
```

---

## Package Categories

ZEN-OS organizes software into focused package lists. Each file in `config/package-lists/` is a curated selection:

| File | Purpose |
|------|---------|
| `base.list.chroot` | Core system: systemd, sudo, network-manager, UFW, AppArmor, Flatpak |
| `desktop-kde.list.chroot` | Full KDE Plasma desktop with SDDM, Dolphin, Konsole, Kvantum |
| `gaming-platforms.list.chroot` | Steam, Wine, MangoHud, GameMode, DXVK, vkBasalt, GOverlay |
| `gpu-drivers.list.chroot` | Mesa Vulkan (AMD/Intel), NVIDIA detect, Vulkan tools |
| `dev-core.list.chroot` | Build tools, Python, Node.js, Rust, Docker, QEMU, Wireshark |
| `cad-native.list.chroot` | FreeCAD, LibreCAD, OpenSCAD, SolveSpace |
| `eda-native.list.chroot` | KiCad + 3D packages, Fritzing, GNU Radio, I2C/GPIO tools |
| `sim-native.list.chroot` | Octave, NumPy, SciPy, Matplotlib, Jupyter |
| `multimedia.list.chroot` | PipeWire, FFmpeg, GStreamer, VLC, fonts (Noto, JetBrains Mono) |
| `firmware.list.chroot` | AMD, Intel, Realtek, Broadcom, QLogic firmware |
| `monitoring.list.chroot` | btop, nvtop, lm-sensors, smartmontools |
| `controllers.list.chroot` | Xbox, Steam devices, controller utilities |
| `hardware-io.list.chroot` | Arduino, AVR tools, hardware detection |

---

## Build Hooks

Hooks run at specific points during the live-build process to configure the system:

| Hook | Purpose |
|------|---------|
| `00-multiarch.hook.chroot` | Enable i386, install Steam + Wine + 32-bit GPU libs |
| `01-sddm-enable.hook.chroot` | Enable SDDM display manager |
| `05-gamemode.hook.chroot` | Enable GameMode daemon |
| `08-cpu-perf.hook.chroot` | Set CPU governor to performance mode |
| `10-audio.hook.chroot` | Configure PipeWire low-latency audio |
| `20-security.hook.chroot` | UFW rules, AppArmor enforcement, SSH hardening |
| `25-first-boot.hook.chroot` | Enable first-boot wizard service |
| `30-plymouth.hook.chroot` | Set Plymouth boot splash theme |
| `99-zenos-cleanup.hook.chroot` | Remove GNOME (if pulled), fix SDDM autologin, set session |

---

## MCP Server

ZEN-OS includes an MCP (Model Context Protocol) server for AI-assisted build/test/release automation:

```json
{
  "mcpServers": {
    "zenos-build": {
      "command": "python3",
      "args": ["mcp-server/server.py"],
      "env": { "ZENOS_WORKSPACE": "/path/to/zen-os" }
    }
  }
}
```

**Available tools:**
- `build_iso` — Build the ISO in Docker with timeout control
- `boot_test_iso` — Boot ISO in QEMU, verify desktop loads
- `verify_iso_packages` — Check packages inside the built ISO
- `run_smoke_test` — Full automated smoke test suite
- `prepare_release` — Generate checksums, release notes
- `start_vm` / `stop_vm` / `capture_screenshot` — VM lifecycle control
- `create_snapshot` / `load_snapshot` — VM snapshot management
- `get_project_status` — Comprehensive project status dashboard

---

## Testing Pipeline

ZEN-OS uses a multi-layer testing approach:

```
Docker (package resolution) → QEMU (boot test) → Vision (screenshot analysis) → RMC (interaction)
```

### Run Tests

```bash
# Docker: verify all packages resolve without conflicts
make test-docker

# QEMU: boot ISO, verify SDDM + KDE Plasma loads
make test-qemu

# Vision: analyze screenshots for desktop indicators
make test-vision

# Full automated test
./scripts/test-vm.sh --docker
./scripts/smoke-test.sh
```

---

## Roadmap

| Phase | Status | Description |
|-------|--------|-------------|
| Phase 0: Foundation | Complete | Build environment, live-build config, Docker pipeline |
| Phase 1: Gaming | Complete | Liquorix kernel, Steam, Wine, DXVK, MangoHud, GameMode |
| Phase 2: Engineering | Complete | FreeCAD, KiCad, dev tools, Docker, ROS 2 repo ready |
| Phase 3: Theming | Complete | GRUB theme, Plymouth splash, SDDM login, KDE Plasma theme |
| Phase 4: Security | Complete | AppArmor, UFW, unattended upgrades, SSH hardening |
| Phase 5: First-Boot | Complete | Welcome wizard, NVIDIA driver installer, Flatpak selector |
| Phase 6: Handheld | Complete | Controller udev rules, Steam Deck support, TDP control |
| Phase 7: MCP | Complete | FastMCP server for build/test/release automation |
| Phase 8: CI/CD | Planned | GitHub Actions for automated testing on push |
| Phase 9: GNOME Edition | Planned | Alternative GNOME desktop (v1.1) |
| Phase 10: APT Repo | Planned | Custom Debian repository for ZEN-OS packages |

---

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines. PRs welcome!

Areas that need help:
- Theme refinement (GRUB, Plymouth, SDDM, KDE)
- Handheld device support (fan curves, controller mappings)
- Translation / localization
- Documentation and guides

---

## Security

See [SECURITY.md](SECURITY.md) for responsible disclosure.

---

## License

ZEN-OS is free software. The build system and configuration files are released under [GPL-3.0](LICENSE).

Individual packages retain their own licenses. Debian packages are distributed under their respective open-source licenses.

---

## Acknowledgments

- [Debian Live Systems](https://live-team.pages.debian.net/live-manual/) — The live-build framework that makes this possible
- [Nobara Linux](https://nobara-project.org/) — Inspiration for a gaming-first desktop experience
- [Liquorix](https://liquorix.net/) — Gaming-tuned kernel for Debian
- [Valve / Steam](https://store.steampowered.com/) — Proton, Steam Runtime, handheld support
- [Mesa](https://www.mesa3d.org/) — Open-source GPU drivers
- [KDE Plasma](https://kde.org/plasma-desktop/) — The desktop environment

---

<p align="center">
  <strong>Built for engineers. Tuned for gaming. Powered by Debian.</strong>
</p>
