# ZEN-OS Makefile — build, validate, inspect and release

.PHONY: all build build-native clean distclean docker-image test test-static test-preflight test-iso test-all smoke release

IMAGE_NAME := zen-os-build
IMAGE_TAG  := latest

all: build

docker-image:
	@echo "Building Docker image..."
	docker build -t $(IMAGE_NAME):$(IMAGE_TAG) -f Dockerfile.build .

build: docker-image
	@echo "Building ZEN-OS ISO..."
	docker run --rm --privileged -v "$(PWD):/build" -w /build $(IMAGE_NAME):$(IMAGE_TAG) bash scripts/build.sh

build-native:
	@echo "Building ZEN-OS ISO (native Debian/Trixie host)..."
	bash scripts/build.sh

clean:
	@echo "Cleaning live-build artifacts..."
	docker run --rm --privileged -v "$(PWD):/build" -w /build $(IMAGE_NAME):$(IMAGE_TAG) bash -c "lb clean --purge 2>/dev/null || true"

distclean: clean
	docker rmi $(IMAGE_NAME):$(IMAGE_TAG) 2>/dev/null || true

test: test-all

test-static:
	@echo "Checking shell syntax and required ZEN-OS launch targets..."
	@bash -n auto/config scripts/*.sh config/hooks/live/*.hook.chroot config/includes.chroot/usr/local/lib/zenos/*.sh
	@for f in config/includes.chroot/usr/share/applications/zenos-*.desktop; do \
		target=$$(grep -Eo '/usr/local/lib/zenos/[A-Za-z0-9._-]+\.sh' "$$f" | head -n1 || true); \
		[ -z "$$target" ] || [ -f "config/includes.chroot$$target" ] || { echo "Missing target $$target from $$f"; exit 1; }; \
	done
	@echo "Static checks passed."

test-preflight: docker-image
	@echo "Resolving requested Debian packages..."
	docker run --rm $(IMAGE_NAME):$(IMAGE_TAG) bash scripts/package-preflight.sh

test-iso:
	@echo "Inspecting built ISO..."
	docker run --rm -v "$(PWD):/build" -w /build $(IMAGE_NAME):$(IMAGE_TAG) bash scripts/verify-iso.sh

test-all: test-static test-preflight
	@echo "Repository and package preflight checks passed."

smoke:
	@echo "Starting VM smoke-test tooling (requires a built ISO and local QEMU/VNC dependencies)..."
	bash scripts/smoke-test.sh

release: test-iso
	@echo "ISO verified. Release automation can now package checksums/artifacts."
	@command -v scripts/generate-checksums.sh >/dev/null 2>&1 || true
	@[ ! -f scripts/generate-checksums.sh ] || bash scripts/generate-checksums.sh
	@[ ! -f scripts/split-iso.sh ] || bash scripts/split-iso.sh
	@[ ! -f scripts/create-torrent.sh ] || bash scripts/create-torrent.sh
	@[ ! -f scripts/create-release.sh ] || bash scripts/create-release.sh
