# ZEN-OS Roadmap

This roadmap focuses on making ZEN-OS trustworthy as a daily-driver distribution before adding more headline features.

## Release readiness — highest priority

- Produce a current ISO from the hardened tree.
- Pass package-resolution and static ISO verification.
- Boot-test the image in UEFI QEMU.
- Test installation to a virtual disk, then boot the installed system.
- Publish SHA-256/SHA-512 checksums with each ISO.
- Attach a real ISO asset to a GitHub prerelease.
- Maintain a public hardware test matrix.

## Hardware validation

Target real-machine coverage:

- AMD Radeon desktop
- Intel iGPU laptop
- NVIDIA desktop/laptop
- Wi-Fi/Bluetooth from Intel and Realtek
- laptop suspend/resume
- multi-monitor Wayland
- game controllers
- at least one handheld PC

Results should distinguish **tested**, **reported working**, and **untested**.

## Desktop polish

- Improve first-run onboarding.
- Add a clearer installer entry point.
- Add recovery/help shortcuts.
- Improve Update Center progress/error reporting.
- Expand ZEN-OS Doctor with install/boot diagnostics.
- Add localization infrastructure.

## Gaming

- Validate Steam/Proton on actual installs.
- Validate Vulkan 32-bit and 64-bit paths on AMD/Intel/NVIDIA.
- Track anti-cheat compatibility as game-specific, not distro-wide.
- Evaluate a supported Gamescope distribution path before advertising it as included.
- Expand controller/handheld validation.

## Engineering

- Validate FreeCAD/KiCad/OpenSCAD/GNU Radio launch behavior on the built ISO.
- Add optional engineering profiles so users can choose lighter or full images in the future.
- Document USB/serial permissions for embedded development.

## Security and maintenance

- Keep inbound services opt-in.
- Keep Debian security updates automatic.
- Add periodic package/kernel pin freshness checks.
- Add dependency/SBOM reporting for releases.
- Add signed release artifacts when release automation matures.

## Later ideas

- custom ZEN-OS APT repository
- optional alternate desktop edition
- recovery snapshots/rollback design
- image variants (Gaming / Engineering / Minimal)
- installer telemetry-free hardware compatibility export, opt-in only

Features move to “complete” only after the code exists and has a reproducible validation path.
