# Building ZEN-OS from Source

A step-by-step guide to build the ZEN-OS ISO on your machine. No prior Linux distribution building experience needed.

---

## What You'll Need

| Requirement | Details |
|-------------|---------|
| **Operating System** | Any OS that runs Docker (Linux, macOS, Windows with WSL2) |
| **Docker** | [Install Docker](https://docs.docker.com/get-docker/) — must support `--privileged` mode |
| **Disk space** | ~20 GB free |
| **RAM** | 4 GB minimum |
| **Time** | 15-45 minutes (mostly downloading packages) |
| **Internet** | Required during build (downloads ~3 GB of Debian packages) |

---

## Quick Start (3 commands)

```bash
git clone https://github.com/zarigata/zen-os.git
cd zen-os
make build
```

When it finishes, you'll find the ISO at `live-image-amd64.hybrid.iso`.

That's it. Read on for details, troubleshooting, and alternative methods.

---

## Step-by-Step Walkthrough

### Step 1: Install Docker

**Linux (Debian/Ubuntu):**
```bash
sudo apt install docker.io
sudo usermod -aG docker $USER
# Log out and back in for group change to take effect
```

**Linux (Fedora):**
```bash
sudo dnf install docker
sudo systemctl enable --now docker
sudo usermod -aG docker $USER
```

**macOS:**
Download [Docker Desktop](https://www.docker.com/products/docker-desktop/) and install it.

**Windows:**
Enable WSL2, then install [Docker Desktop](https://www.docker.com/products/docker-desktop/) with WSL2 backend.

### Step 2: Clone the Repository

```bash
git clone https://github.com/zarigata/zen-os.git
cd zen-os
```

### Step 3: Build the ISO

```bash
make build
```

This does three things automatically:
1. **Fetches the Liquorix kernel** (~128 MB download from liquorix.net)
2. **Builds the Docker image** (`zen-os-build:latest`) with all build tools
3. **Runs the full live-build pipeline** inside Docker

You'll see progress output like:
```
[0/3] Fetching kernel packages...
[1/3] Cleaning previous build...
[2/3] Running lb config...
[3/3] Running lb build (this takes 15-45 minutes)...

==========================================
  BUILD SUCCESS
  ISO: live-image-amd64.hybrid.iso (4.7G)
  Duration: 28m 39s
==========================================
```

### Step 4: Write to USB

```bash
# Linux / macOS
sudo dd if=live-image-amd64.hybrid.iso of=/dev/sdX bs=4M status=progress && sync

# Replace /dev/sdX with your USB drive (use lsblk to find it)
```

**Or use [Ventoy](https://www.ventoy.net/)** — just copy the ISO file onto a Ventoy-formatted USB drive. No dd needed.

### Step 5: Boot It

1. Insert USB into target machine
2. Enter BIOS/UEFI boot menu (usually F12, F2, or Del)
3. Select the USB drive
4. ZEN-OS boots into a live KDE Plasma desktop

---

## Alternative: Build Without Docker

If you're already running Debian Trixie (or Ubuntu 24.04+):

```bash
sudo apt install live-build debootstrap squashfs-tools xorriso \
    grub-pc-bin grub-efi-amd64-bin grub-efi-amd64-signed \
    shim-signed ovmf dosfstools mtools syslinux-common isolinux

make build-native
```

---

## Other Make Targets

```bash
make build          # Full build (Docker) — the standard way
make build-native   # Build without Docker (Debian host only)
make clean          # Remove build artifacts (keeps Docker image)
make distclean      # Remove everything including Docker image
make test-all       # Run automated test suites
make release        # Prepare release artifacts (checksums, split ISO)
```

---

## Testing the ISO

Before installing on real hardware, test in a VM:

```bash
# Easiest way — Docker-based QEMU with web viewer:
./scripts/test-vm.sh --docker

# Then open http://localhost:8006 in your browser
```

Or with native QEMU:
```bash
./scripts/test-vm.sh --web
```

---

## Troubleshooting

### "Permission denied" from Docker
```bash
sudo usermod -aG docker $USER
# Log out and back in
```

### Build fails with package download errors
The build downloads packages from Debian mirrors. If it fails:
1. Check your internet connection
2. Re-run `make build` — it's safe to re-run, will pick up where it left off
3. If a specific package fails, check [Debian package status](https://packages.debian.org/)

### "No space left on device"
The build needs ~20 GB. Check with `df -h`. Clean up with `make clean`.

### Docker build fails
```bash
# Remove old build image and retry
docker rmi zen-os-build:latest
make build
```

### ISO won't boot
- Make sure you selected **UEFI boot** (not Legacy/BIOS)
- Try re-writing the USB with `dd` (some tools corrupt the image)
- Verify the ISO checksum:
  ```bash
  sha256sum live-image-amd64.hybrid.iso
  # Should match the checksum in the release notes
  ```

---

## What Gets Built

The ISO contains:

- **Debian Trixie** base system
- **KDE Plasma** desktop with ZEN-OS custom theme
- **Liquorix 7.0.5** gaming-tuned kernel
- **Steam, Wine 10.0, DXVK** gaming stack
- **FreeCAD, KiCad, Docker, Jupyter** engineering tools
- **PipeWire** low-latency audio
- **UFW firewall + AppArmor** security
- **First-boot wizard** for hardware setup

All configured, all themed, all ready to use.

---

## Clean Up After Build

```bash
# Remove build artifacts (ISO is kept)
make clean

# Remove everything including Docker image (~2 GB)
make distclean
```

The ISO file (`live-image-amd64.hybrid.iso`) is kept after clean.
