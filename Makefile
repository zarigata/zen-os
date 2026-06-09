# ZEN-OS Makefile — orchestrates build, test, and release

.PHONY: all build clean test test-docker test-qemu test-vision test-rmc test-games test-all release docker-image

# Docker image name
IMAGE_NAME := zen-os-build
IMAGE_TAG  := latest

# Default target
all: docker-image build

# Build the Docker build environment image
docker-image:
	@echo "Building Docker image..."
	docker build -t $(IMAGE_NAME):$(IMAGE_TAG) -f Dockerfile.build .

# Build the ISO inside Docker container
build: docker-image
	@echo "Building ZEN-OS ISO..."
	docker run --rm \
		--privileged \
		-v "$(PWD):/build" \
		-w /build \
		$(IMAGE_NAME):$(IMAGE_TAG) \
		bash scripts/build.sh

# Build without Docker (requires Debian host with live-build)
build-native:
	@echo "Building ZEN-OS ISO (native)..."
	bash scripts/build.sh

# Clean build artifacts
clean:
	docker run --rm \
		--privileged \
		-v "$(PWD):/build" \
		-w /build \
		$(IMAGE_NAME):$(IMAGE_TAG) \
		bash -c "lb clean --purge 2>/dev/null || true"
	@echo "Clean complete."

# Full clean including Docker image
distclean: clean
	docker rmi $(IMAGE_NAME):$(IMAGE_TAG) 2>/dev/null || true

# Test targets
test-docker:
	@echo "Running Docker test suite..."
	bash tests/docker/test-package-resolution.sh

test-qemu:
	@echo "Running QEMU boot tests..."
	bash tests/qemu/harness.sh

test-vision:
	@echo "Running Vision LLM analysis..."
	bash tests/vision/run-all.sh

test-rmc:
	@echo "Running RMC interaction tests..."
	bash tests/rmc/run-all.sh

test-games:
	@echo "Running game stack tests..."
	bash tests/games/run-all.sh

test-all: test-docker test-qemu test-vision test-rmc test-games
	@echo "All tests complete."

# Release targets
release:
	@echo "Creating release..."
	bash scripts/generate-checksums.sh
	bash scripts/split-iso.sh
	bash scripts/create-torrent.sh
	bash scripts/create-release.sh
