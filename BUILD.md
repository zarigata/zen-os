# Building ZEN-OS

This guide describes the build path that matches the current repository.

## Requirements

| Requirement | Recommendation |
|---|---|
| Host | Linux is easiest; Docker Desktop/WSL2 can also work |
| Docker | Current Docker with privileged containers available |
| Disk | At least 25 GB free; more is safer |
| RAM | 8 GB recommended |
| Internet | Required for Debian and Liquorix packages |
| Architecture | Build output is amd64 |

## Standard build

```bash
git clone https://github.com/zarigata/zen-os.git
cd zen-os
make build
```

The Makefile builds `Dockerfile.build`, runs the live-build pipeline in a privileged container, and writes `live-image-amd64.hybrid.iso` in the repository root.

The build currently pins Liquorix:

- kernel version: **7.2.7-1**
- package release: **7.2-12.2~trixie**

The exact pin is recorded in `versions.lock` and `scripts/fetch-kernel.sh`.

## Preflight checks

Before spending time on a full ISO build:

```bash
make test-all
```

This runs real repository/static checks plus a Debian Trixie package-resolution simulation.

You can run just the package check with:

```bash
make test-preflight
```

## Build steps

`scripts/build.sh` performs:

1. fetch the pinned Liquorix kernel packages
2. clean previous live-build state
3. run `lb config`
4. run `lb build`
5. report the generated ISO and build log

A failed Liquorix download is treated as a hard failure so stale kernel packages cannot silently survive into the build.

## Verify the resulting ISO

Do not treat “`lb build` returned zero” as the only release check.

```bash
make test-iso
```

The verifier checks:

- ISO exists and is a plausible size
- ISO9660 structure can be read
- squashfs live filesystem exists
- GRUB/EFI boot content exists
- selected package-manifest entries
- ZEN-OS Control Center, Security Center, Doctor and Update Center are present in squashfs
- OS identity is present

Then generate release checksums:

```bash
make release
```

This writes SHA-256 and SHA-512 checksum files next to the ISO.

## VM test

Native QEMU/noVNC:

```bash
./scripts/test-vm.sh --web
```

Docker QEMU mode:

```bash
./scripts/test-vm.sh --docker
```

The VM tooling requires a built ISO. Some environments, especially hosted CI runners, do not expose KVM and are therefore not equivalent to a local hardware-accelerated VM.

## Native Debian build

A native Trixie host can run:

```bash
make build-native
```

Docker remains the preferred path because it reduces differences between build hosts.

## Troubleshooting

### Liquorix package failure

If a kernel package has disappeared from the Liquorix pool, update **both** `versions.lock` and `scripts/fetch-kernel.sh` to a Trixie-compatible release. Do not leave older Liquorix .deb files in `config/packages.chroot/`.

The fetch script removes stale Liquorix packages before downloading the pinned set.

### Package cannot be installed

Run:

```bash
make test-preflight
```

This will identify package names that are missing or whose combined dependency set cannot be solved against Debian Trixie.

### Docker permission denied

On Debian/Ubuntu hosts:

```bash
sudo usermod -aG docker "$USER"
```

Log out and back in before retrying.

### No space left

Live-build uses substantial temporary space. Check both the repository filesystem and Docker storage:

```bash
df -h
docker system df
```

Use `make clean` to remove live-build state and `make distclean` if the build image also needs to be removed.

### ISO boots but desktop fails

Collect:

```bash
journalctl -b -p warning
systemctl --failed
/usr/local/lib/zenos/doctor.sh report
```

Attach the Doctor report to a GitHub issue.

## Writing to USB

After verifying the checksum, write the ISO with a trusted imaging tool or Ventoy. With `dd`, triple-check the destination device before writing:

```bash
sudo dd if=live-image-amd64.hybrid.iso of=/dev/sdX bs=4M status=progress conv=fsync
```

The target device is overwritten.
