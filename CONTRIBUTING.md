# Contributing to ZEN-OS

Thanks for helping improve ZEN-OS. The highest-value contributions are reproducible fixes and real-hardware reports.

## Quick start

```bash
git clone https://github.com/zarigata/zen-os.git
cd zen-os
git checkout -b fix/my-change
make test-all
```

After changing build configuration, hooks, packages or files shipped into the ISO, a full local build is strongly recommended:

```bash
make build
make test-iso
```

## Repository layout

- `config/package-lists/` — Debian packages intended for the live image
- `config/hooks/live/` — scripts executed inside the target chroot during live-build
- `config/includes.chroot/` — files copied into the live/installed filesystem
- `config/includes.chroot/usr/local/lib/zenos/` — ZEN-OS desktop/maintenance scripts
- `scripts/` — build and validation tooling
- `docs/` — GitHub Pages website
- `mcp-server/` — optional AI-assisted build/test tooling

## Package changes

Keep package lists simple: one package name per line and comments beginning with `#`.

Before opening a PR:

```bash
make test-preflight
```

The preflight uses Debian Trixie repositories and performs both package-name checks and a combined simulated install. A package that exists individually can still break the combined dependency set, so both checks matter.

Packages requiring special multiarch sequencing belong in the relevant build hook rather than being dropped blindly into a normal package list.

## Build hooks

Hooks should:

- use a shell shebang
- use strict error handling when failure should stop the image build
- be idempotent where practical
- log meaningful ZEN-OS-prefixed messages
- avoid hardcoded personal paths
- avoid hiding required-package failures behind unconditional `|| true`

Optional hardware-specific behavior may fail gracefully, but required build inputs should fail loudly.

## Shipped ZEN-OS tools

Custom tools live under:

```
config/includes.chroot/usr/local/lib/zenos/
```

Desktop launchers live under:

```
config/includes.chroot/usr/share/applications/
```

CI checks that ZEN-OS launchers do not point at missing scripts.

When adding a tool:

1. add the script
2. add a launcher if it is user-facing
3. integrate it into Control Center when appropriate
4. document it in README/USER_GUIDE
5. ensure it works without embedding credentials or machine-specific paths

## Testing levels

### Required for every PR

```bash
make test-all
```

This covers static repository checks and package/dependency resolution.

### Required for release/build changes

```bash
make build
make test-iso
```

The ISO verifier checks image structure, boot payload and key ZEN-OS files inside squashfs.

### Recommended for desktop/boot changes

```bash
./scripts/test-vm.sh --web
```

Then test the actual behavior in the VM.

Real-hardware testing is especially valuable for GPU drivers, Wi-Fi/Bluetooth, suspend/resume, audio, controllers and installers.

## Bug reports

Use the GitHub bug-report form:

https://github.com/zarigata/zen-os/issues/new/choose

Please include:

- exact Git commit or release
- live session vs installed system
- CPU/GPU and machine model
- exact reproduction steps
- expected vs actual behavior
- relevant logs
- a ZEN-OS Doctor report when possible

Generate a report with:

```bash
/usr/local/lib/zenos/doctor.sh report
```

Remove anything you consider sensitive before posting.

## Pull requests

Prefer focused PRs. Explain:

- what problem is being solved
- what changed
- how it was tested
- whether it changes packages, boot, security or networking
- hardware used for testing, if applicable

Do not mark hardware behavior “supported” solely because it worked in a container or static package test.

## Security issues

Do not publish an exploitable vulnerability in a normal issue. Follow [SECURITY.md](SECURITY.md) and use private vulnerability reporting.

## Documentation standard

ZEN-OS documentation should distinguish:

- **implemented**
- **validated in CI**
- **validated in a VM**
- **validated on physical hardware**
- **planned**

Avoid advertising planned tools as already shipped.

## License

By contributing, you agree that your contribution is distributed under the repository license and that third-party package licenses remain their own.
