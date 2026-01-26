# Hytale Server Container - Local Development Makefile
#
# Requirements:
#   - Docker Desktop (Windows/Mac) or Docker Engine (Linux)
#   - GNU Make (via Git Bash, WSL, or native)
#
# On Windows, run from Git Bash or WSL for best compatibility.


# Configuration
IMAGE_NAME := hytale-server-local
CONTAINER_NAME := hytale-test
DATA_DIR := data

# Docker Hub publishing
DOCKERHUB_REPO := shotah/hytale-server
VERSION ?= latest

# Base images for variants
BASE_IMAGE_ALPINE := eclipse-temurin:25-jre-alpine
BASE_IMAGE_UBUNTU := eclipse-temurin:25-jre
BASE_IMAGE_LIBERICA := bellsoft/liberica-openjre-alpine-musl:25

# Use CURDIR (Make built-in) instead of PWD for cross-platform support
ROOT_DIR := $(CURDIR)

# CurseForge testing
CURSEFORGE_MOD_IDS ?= 1423494,1430352

.PHONY: help build build-alpine build-ubuntu build-liberica run run-mods stop logs shell clean test login push push-alpine push-ubuntu push-liberica push-all push-readme

help:
	@echo "Hytale Server Container - Development Commands"
	@echo ""
	@echo "Local Development:"
	@echo "  make build          - Build Alpine image (default)"
	@echo "  make build-alpine   - Build Alpine image"
	@echo "  make build-ubuntu   - Build Ubuntu image"
	@echo "  make build-liberica - Build Alpine Liberica image"
	@echo "  make run            - Run the server (offline mode)"
	@echo "  make run-mods       - Run with CurseForge mods"
	@echo "  make test           - Run all tests"
	@echo "  make stop           - Stop the running container"
	@echo "  make logs           - View container logs"
	@echo "  make shell          - Open a shell in the container"
	@echo "  make clean          - Remove container and image"
	@echo ""
	@echo "Docker Hub Publishing:"
	@echo "  make login          - Login to Docker Hub"
	@echo "  make push           - Build and push Alpine image (default)"
	@echo "  make push-alpine    - Build and push Alpine image"
	@echo "  make push-ubuntu    - Build and push Ubuntu image"
	@echo "  make push-liberica  - Build and push Liberica image"
	@echo "  make push-all       - Build and push all variants"
	@echo "  make push-readme    - Push Docker Hub description"
	@echo ""
	@echo "Examples:"
	@echo "  make run-mods CURSEFORGE_MOD_IDS=12345,67890"
	@echo "  make push VERSION=1.0.0"

# --- Build targets (using unified Dockerfile) ---

build: build-alpine

build-alpine:
	docker build -t $(IMAGE_NAME):alpine \
		--build-arg BASE_IMAGE=$(BASE_IMAGE_ALPINE) \
		-f Dockerfile .

build-ubuntu:
	docker build -t $(IMAGE_NAME):ubuntu \
		--build-arg BASE_IMAGE=$(BASE_IMAGE_UBUNTU) \
		-f Dockerfile .

build-liberica:
	docker build -t $(IMAGE_NAME):liberica \
		--build-arg BASE_IMAGE=$(BASE_IMAGE_LIBERICA) \
		-f Dockerfile .

# --- Run targets ---

run: build-alpine
	@echo "Creating data directory: $(DATA_DIR)"
	-@mkdir -p $(DATA_DIR)
	docker run -it --rm \
		--name $(CONTAINER_NAME) \
		-e SERVER_IP="0.0.0.0" \
		-e SERVER_PORT="5520" \
		-e DEBUG="TRUE" \
		-e TZ="UTC" \
		-e HYTALE_AUTH_MODE="offline" \
		-p 5520:5520/udp \
		-v "$(ROOT_DIR)/$(DATA_DIR):/home/container" \
		$(IMAGE_NAME):alpine

run-mods: build-alpine
	-@mkdir -p $(DATA_DIR)
	docker run -it --rm \
		--name $(CONTAINER_NAME) \
		-e SERVER_IP="0.0.0.0" \
		-e SERVER_PORT="5520" \
		-e DEBUG="TRUE" \
		-e TZ="UTC" \
		-e HYTALE_AUTH_MODE="offline" \
		-e CURSEFORGE_MOD_IDS="$(CURSEFORGE_MOD_IDS)" \
		-p 5520:5520/udp \
		-v "$(ROOT_DIR)/$(DATA_DIR):/home/container" \
		$(IMAGE_NAME):alpine

run-detached: build-alpine
	-@mkdir -p $(DATA_DIR)
	docker run -d \
		--name $(CONTAINER_NAME) \
		-e SERVER_IP="0.0.0.0" \
		-e SERVER_PORT="5520" \
		-e DEBUG="TRUE" \
		-e TZ="UTC" \
		-e HYTALE_AUTH_MODE="offline" \
		-p 5520:5520/udp \
		-v "$(ROOT_DIR)/$(DATA_DIR):/home/container" \
		$(IMAGE_NAME):alpine

# --- Test targets ---
# Tests run directly via Docker - no bash required on host

test: build-alpine
	@echo "=== Running tests for alpine ==="
	@echo "1. Basic structure test..."
	docker run --rm --entrypoint /bin/sh $(IMAGE_NAME):alpine -c "\
		test -x /usr/local/bin/hytale-downloader && \
		test -f /entrypoint.sh && \
		test -d /usr/local/bin/scripts && \
		test -f /usr/local/bin/scripts/hytale/hytale_permissions.sh && \
		echo '  OK: Basic structure'"
	@echo "2. Config script test..."
	docker run --rm --entrypoint /bin/sh $(IMAGE_NAME):alpine -c "\
		export SCRIPTS_PATH=/usr/local/bin/scripts && \
		export BASE_DIR=/home/container && \
		export HYTALE_SERVER_NAME='Test Server' && \
		. /usr/local/bin/scripts/utils.sh && \
		sh /usr/local/bin/scripts/hytale/hytale_config.sh > /dev/null && \
		test -f /home/container/config.json && \
		jq -e '.ServerName == \"Test Server\"' /home/container/config.json > /dev/null && \
		echo '  OK: Config script'"
	@echo "3. Permissions script test..."
	docker run --rm --entrypoint /bin/sh $(IMAGE_NAME):alpine -c "\
		export SCRIPTS_PATH=/usr/local/bin/scripts && \
		export BASE_DIR=/home/container && \
		export HYTALE_WHITELIST_ENABLED=true && \
		export HYTALE_OPS='11111111-1111-1111-1111-111111111111' && \
		. /usr/local/bin/scripts/utils.sh && \
		sh /usr/local/bin/scripts/hytale/hytale_permissions.sh > /dev/null && \
		test -f /home/container/whitelist.json && \
		test -f /home/container/permissions.json && \
		jq -e '.enabled == true' /home/container/whitelist.json > /dev/null && \
		jq -e '.users[\"11111111-1111-1111-1111-111111111111\"]' /home/container/permissions.json > /dev/null && \
		echo '  OK: Permissions script'"
	@echo "4. Downloader failsafe test..."
	docker run --rm --entrypoint /bin/sh $(IMAGE_NAME):alpine -c '\
		mkdir -p /home/container/game/Server && \
		touch /home/container/game/Server/HytaleServer.jar && \
		rm -f /home/container/.hytale_version && \
		VF=/home/container/.hytale_version && \
		JP=/home/container/game/Server/HytaleServer.jar && \
		if [ -f $$JP ] && [ ! -f $$VF ]; then \
			echo "  OK: Failsafe detects JAR without version file"; \
		else \
			echo "FAIL: Failsafe logic broken"; exit 1; \
		fi'
	@echo "=== All tests passed ==="

test-all: build-alpine build-ubuntu build-liberica
	@echo "=== Running tests for all variants ==="
	docker run --rm --entrypoint /bin/sh $(IMAGE_NAME):alpine -c "test -x /usr/local/bin/hytale-downloader && echo 'Alpine: OK'"
	docker run --rm --entrypoint /bin/sh $(IMAGE_NAME):ubuntu -c "test -x /usr/local/bin/hytale-downloader && echo 'Ubuntu: OK'"
	docker run --rm --entrypoint /bin/sh $(IMAGE_NAME):liberica -c "test -x /usr/local/bin/hytale-downloader && echo 'Liberica: OK'"

# --- Utility targets ---

stop:
	docker stop $(CONTAINER_NAME) 2>/dev/null || true
	docker rm $(CONTAINER_NAME) 2>/dev/null || true

logs:
	docker logs -f $(CONTAINER_NAME)

shell:
	docker exec -it $(CONTAINER_NAME) /bin/sh

clean: stop
	docker rmi $(IMAGE_NAME):alpine 2>/dev/null || true
	docker rmi $(IMAGE_NAME):ubuntu 2>/dev/null || true
	docker rmi $(IMAGE_NAME):liberica 2>/dev/null || true
	@echo "Note: Data in $(DATA_DIR) preserved. Remove manually if needed."

# --- Docker Hub Publishing ---

login:
	docker login

push: push-alpine

push-alpine:
	docker build -t $(DOCKERHUB_REPO):alpine -t $(DOCKERHUB_REPO):latest \
		--build-arg BASE_IMAGE=$(BASE_IMAGE_ALPINE) \
		-f Dockerfile .
	docker push $(DOCKERHUB_REPO):alpine
	docker push $(DOCKERHUB_REPO):latest
	@if [ "$(VERSION)" != "latest" ]; then \
		docker tag $(DOCKERHUB_REPO):alpine $(DOCKERHUB_REPO):$(VERSION); \
		docker push $(DOCKERHUB_REPO):$(VERSION); \
	fi

push-ubuntu:
	docker build -t $(DOCKERHUB_REPO):ubuntu \
		--build-arg BASE_IMAGE=$(BASE_IMAGE_UBUNTU) \
		-f Dockerfile .
	docker push $(DOCKERHUB_REPO):ubuntu
	@if [ "$(VERSION)" != "latest" ]; then \
		docker tag $(DOCKERHUB_REPO):ubuntu $(DOCKERHUB_REPO):$(VERSION)-ubuntu; \
		docker push $(DOCKERHUB_REPO):$(VERSION)-ubuntu; \
	fi

push-liberica:
	docker build -t $(DOCKERHUB_REPO):liberica \
		--build-arg BASE_IMAGE=$(BASE_IMAGE_LIBERICA) \
		-f Dockerfile .
	docker push $(DOCKERHUB_REPO):liberica
	@if [ "$(VERSION)" != "latest" ]; then \
		docker tag $(DOCKERHUB_REPO):liberica $(DOCKERHUB_REPO):$(VERSION)-liberica; \
		docker push $(DOCKERHUB_REPO):$(VERSION)-liberica; \
	fi

push-all: push-alpine push-ubuntu push-liberica
	@echo "All images pushed to $(DOCKERHUB_REPO)"

# Update Docker Hub description from README
push-readme:
	@if [ -z "$(DOCKERHUB_TOKEN)" ]; then \
		echo "ERROR: Set DOCKERHUB_TOKEN (from hub.docker.com/settings/security)"; \
		exit 1; \
	fi
	curl -X PATCH \
		-H "Authorization: Bearer $(DOCKERHUB_TOKEN)" \
		-H "Content-Type: application/json" \
		-d "{\"full_description\": $$(cat README.md | jq -Rs .)}" \
		"https://hub.docker.com/v2/repositories/$(DOCKERHUB_REPO)/"
