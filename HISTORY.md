# ZEN-OS — Development History

A chronological record of ZEN-OS development, from initial concept to current state.

---

## v1.0.0-alpha — Initial Public Release

**Date**: June 2026
**Codename**: "First Light"
**Base**: Debian GNU/Linux 13 (Trixie)
**Kernel**: Liquorix 7.0.5 / Debian 6.12.86
**Desktop**: KDE Plasma (X11 + Wayland)
**ISO Size**: ~3.4 GB

### What's New

Everything. This is the first release.

---

## Development Timeline

### Phase 0 — Foundation (May 2026)

The entire build infrastructure was established from scratch.

- **Build environment**: Docker-based build pipeline (`Dockerfile.build`) running on Debian Trixie. Reproducible on any host OS.
- **live-build configuration**: `auto/config` configured with UEFI GRUB, squashfs, Trixie distribution, all four archive areas (main, contrib, non-free, non-free-firmware).
- **Makefile**: Orchestration layer — `make build`, `make clean`, `make test-all`, `make release`.
- **Package list architecture**: 14 categorized `.list.chroot` files organizing ~300+ packages.
- **First bootable ISO**: Base system + KDE Plasma + firmware → boots to SDDM login prompt.
- **Version locking**: `versions.lock` file tracks exact versions of critical packages.

**Key decisions locked**:
- Debian Trixie (testing) as base — fresh packages, reasonable stability
- KDE Plasma as v1.0 desktop — most customizable, best gaming integrations
- Docker-based builds — works on any host OS
- Squashfs + ISO hybrid — single image for both live USB and installation

### Phase 1 — Gaming Stack (May 2026)

The full gaming stack was integrated and tested.

- **Liquorix kernel 7.0.5**: Gaming-tuned kernel packaged as local `.deb` (repo integration disabled due to Docker SSL issues).
- **Steam**: `steam-installer` via multiarch hook (requires i386).
- **Wine 10.0**: Full 32-bit + 64-bit Wine with winetricks. WineHQ repo disabled (SSL issues in Docker) — using Debian's stable wine instead.
- **i386 multiarch**: Hook `00-multiarch.hook.chroot` enables i386, installs Steam, Wine, and 32-bit GPU libraries (Mesa Vulkan, libGL, libVulkan).
- **Gaming performance**: MangoHud, GameMode daemon, GOverlay, vkBasalt, DXVK 2.6.
- **GPU drivers**: AMD (Mesa Vulkan), Intel (ANV, media VA), NVIDIA (detect only — wizard handles driver install).
- **Mesa 25.0.7**: Current Trixie version (no experimental pinning needed yet).
- **Gaming sysctl**: `vm.swappiness=10`, `vm.max_map_count=2147483642`, scheduler tuning.
- **CPU performance**: Custom systemd service sets governor to `performance`, disables deep C-states.
- **PipeWire audio**: Low-latency gaming profile (quantum=256, min-quantum=128), WirePlumber session manager.
- **Monitoring**: btop, nvtop, lm-sensors, stress-ng.

**Boot verified**: Both UEFI and Legacy BIOS boot working. SDDM login prompt confirmed via QEMU serial console.

### Phase 2 — Engineering Stack (May 2026)

Professional engineering tools across all categories.

- **Development core**: build-essential, CMake, GCC, Clang, Python 3, Node.js, npm, JDK, Rust/Cargo, Docker, Podman, QEMU/libvirt.
- **Networking tools**: nmap, Wireshark, tcpdump, iperf3, traceroute.
- **CAD**: FreeCAD, LibreCAD, OpenSCAD, SolveSpace — all native Debian packages.
- **EDA/Electronics**: KiCad + 3D package library, Fritzing, GNU Radio, I2C/SMBus/GPIO tools.
- **Simulation & Math**: GNU Octave with control/signal packages, NumPy, SciPy, Matplotlib, SymPy, Pandas, Jupyter Notebook.
- **Hardware I/O**: Arduino core, AVR tools, hardware detection utilities.

### Phase 3 — Theming & Branding (May 2026)

Custom visual identity across the entire boot-to-desktop experience.

- **OS identity**: Custom `os-release` (NAME="ZEN-OS", ID=zenos, ID_LIKE=debian).
- **GRUB**: Custom theme with teal color scheme, boot menu, progress bar, splash image.
- **Plymouth**: Boot splash with ZEN-OS branding.
- **SDDM**: Custom login theme (`zenos-sddm`) with autologin for live-user.
- **KDE Plasma**: Kvantum widget style, Breeze icons, Papirus icon theme, custom color scheme.
- **Wallpapers**: AI-generated ZEN-OS themed wallpapers in `wallpapers/` directory.
- **Fonts**: Noto Sans, JetBrains Mono, Hack, DejaVu, Noto CJK, Noto Color Emoji.

### Phase 4 — Security Configuration (May 2026)

Pragmatic security — 75% hardened, 25% convenience.

- **UFW firewall**: Default deny incoming, allow outgoing. Allow SSH (rate-limited), KDE Connect, Samba.
- **AppArmor**: Enabled via kernel parameters, profiles enforced at build time.
- **Unattended upgrades**: Automatic security updates (excludes Mesa and Liquorix — too risky for auto-update).
- **SSH hardening**: Root login disabled, host keys regenerated on first boot.
- **Kernel hardening**: `kptr_restrict`, `dmesg_restrict`, `rp_filter`, SYN cookies.
- **Root account**: Locked by default. User gets sudo access.

### Phase 5 — First-Boot Wizard (May 2026)

Automated setup on first boot, inspired by Nobara's firstrun.

- **Wizard framework**: Systemd service (`zenos-first-boot.service`) runs on first boot.
- **Hardware detection**: GPU detection (AMD/Intel/NVIDIA), handheld detection, Secure Boot state.
- **NVIDIA driver wizard**: Post-install NVIDIA driver download, DKMS build, Secure Boot MOK enrollment.
- **Flatpak selector**: Category-based app selection (Gaming, Engineering, 3D Printing, Creative).
- **Optimization profiles**: Gaming / Balanced / Battery presets for sysctl and CPU governor.
- **Sudoers**: NOPASSWD rules for wizard scripts.

### Phase 6 — Handheld Support (May 2026)

Support for Steam Deck, ROG Ally, and other handheld gaming PCs.

- **Controller support**: Xbox, Steam, PlayStation, 8BitDo udev rules. `antimicrox` for button mapping.
- **On-screen keyboard**: `maliit-keyboard` for handheld touch input.
- **Steam Big Picture**: Config option to auto-launch Steam in Big Picture mode.
- **Display profiles**: Scripts for 7-inch screen optimization (800p/1200p, 60Hz/120Hz).
- **TDP control**: RyzenAdj-based TDP management for AMD handhelds.

### Phase 7 — MCP Server & Testing (May-June 2026)

AI-assisted testing infrastructure.

- **MCP server**: FastMCP-based server (`mcp-server/server.py`) with 15+ tools for build, test, and release automation.
- **Docker test suite**: Package resolution tests, hook validation, 32-bit verification, Mesa conflict detection.
- **QEMU boot tests**: UEFI + Legacy BIOS boot verification, serial console analysis.
- **Vision tests**: Screenshot analysis with PIL/NumPy — detects desktop, wallpaper, panel presence.
- **Smoke test suite**: Automated 5-test suite (ISO integrity, boot, desktop, services, network).
- **VM management**: `test-vm.sh` with web/noVNC, VNC, MCP, and Docker modes. Snapshot support.

---

## Known Limitations (v1.0.0-alpha)

- **NVIDIA drivers**: Not pre-installed — requires post-install wizard with internet access
- **Gamescope**: Not in Debian repos — requires Flatpak or source build
- **Secure Boot**: Disabled by default — optional MOK enrollment wizard available
- **WineHQ staging**: Using Debian's stable Wine 10.0 instead (WineHQ SSL issues in Docker)
- **Liquorix repo**: Using local `.deb` packages instead of live repo (Docker SSL issues)
- **GNOME edition**: Planned for v1.1 (config exists but disabled)

---

## Build History

| Build | Date | Duration | ISO Size | Status |
|-------|------|----------|----------|--------|
| First bootable ISO | May 2026 | ~45m | ~2.8 GB | PASS — boots to SDDM |
| Gaming stack integrated | May 2026 | ~35m | ~3.2 GB | PASS — Steam + Wine functional |
| Full stack (Phase 0-6) | May 2026 | ~28m | ~3.4 GB | PASS — all services operational |

---

## Contributing to History

When making significant changes, add an entry to this file in your PR:

```
### [Date] — [Brief Description]

- What changed
- Why it changed
- Any breaking changes or migration notes
```
