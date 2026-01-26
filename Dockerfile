# syntax=docker/dockerfile:1.7
#
# Unified Hytale Server Dockerfile
# Supports multiple base images via BUILD_ARG:
#   - eclipse-temurin:25-jre-alpine (default, smallest)
#   - eclipse-temurin:25-jre (Ubuntu-based)
#   - bellsoft/liberica-openjre-alpine-musl:25 (Liberica JRE)
#
# Usage:
#   docker build --build-arg BASE_IMAGE=eclipse-temurin:25-jre-alpine .
#

# Global ARG must be declared before any FROM to be available in later stages
ARG BASE_IMAGE=eclipse-temurin:25-jre-alpine

# --- STAGE 1: Builder (always Alpine for consistency) ---
FROM alpine:3.21 AS builder

RUN apk add --no-cache curl unzip dos2unix

WORKDIR /build

# Download and extract Hytale Downloader
RUN curl -fsSL -o hytale.zip https://downloader.hytale.com/hytale-downloader.zip && \
    unzip -q hytale.zip -d ./hytale && \
    mv ./hytale/hytale-downloader-linux-amd64 ./hytale-downloader && \
    chmod +x ./hytale-downloader && \
    rm -rf hytale hytale.zip

# Prepare scripts (fix line endings and permissions)
COPY scripts/ ./scripts/
COPY entrypoint.sh .
RUN find scripts -type f -name "*.sh" -exec dos2unix {} + && \
    dos2unix entrypoint.sh && \
    chmod -R +x scripts && \
    chmod +x entrypoint.sh

# --- STAGE 2: Final Runtime ---
ARG BASE_IMAGE=eclipse-temurin:25-jre-alpine
FROM ${BASE_IMAGE}

# Build arguments
ARG UID=1000
ARG GID=1000
ARG BUILDTIME=local
ARG VERSION=local
ARG REVISION=local

# OCI Metadata
LABEL org.opencontainers.image.title="Hytale Server" \
    org.opencontainers.image.description="Hytale Docker server image with non-root execution, UDP optimization, and diagnostics. Fork with pre-release and CurseForge mod support." \
    org.opencontainers.image.authors="shotah, deinfreu (original author)" \
    org.opencontainers.image.url="https://github.com/shotah/hytale-server-container" \
    org.opencontainers.image.source="https://github.com/shotah/hytale-server-container" \
    org.opencontainers.image.vendor="shotah" \
    org.opencontainers.image.base.name="https://github.com/deinfreu/hytale-server-container" \
    org.opencontainers.image.version="${VERSION}" \
    org.opencontainers.image.revision="${REVISION}" \
    org.opencontainers.image.created="${BUILDTIME}" \
    org.opencontainers.image.licenses="Apache-2.0"

# Runtime configuration
ENV USER=container \
    HOME=/home/container \
    UID=1000 \
    GID=1000 \
    SCRIPTS_PATH="/usr/local/bin/scripts" \
    SERVER_PORT=5520 \
    SERVER_IP="" \
    JAVA_ARGS="" \
    PROD=FALSE \
    DEBUG=FALSE

# Install packages (platform-specific)
COPY build/ /build-scripts/
RUN --mount=target=/build-scripts,source=build \
    /build-scripts/run.sh install-packages

# Setup user (platform-specific)
RUN --mount=target=/build-scripts,source=build \
    /build-scripts/run.sh setup-user

# Copy artifacts from builder
COPY --from=builder --chown=root:root /build/hytale-downloader /usr/local/bin/hytale-downloader
COPY --from=builder --chown=${USER}:${USER} /build/scripts/ /usr/local/bin/scripts/
COPY --from=builder --chown=${USER}:${USER} /build/entrypoint.sh /entrypoint.sh

# Image metadata file
RUN printf "buildtime=%s\nversion=%s\nrevision=%s\n" "${BUILDTIME}" "${VERSION}" "${REVISION}" > /etc/image.properties

# Final setup
WORKDIR ${HOME}
USER ${USER}
EXPOSE ${SERVER_PORT}/udp
STOPSIGNAL SIGTERM

# Health check - verify server is listening on UDP port
HEALTHCHECK --interval=30s --timeout=5s --start-period=2m --retries=3 \
    CMD ss -ulpn | grep -q ":${SERVER_PORT}" || exit 1

ENTRYPOINT ["/sbin/tini", "--"]
CMD ["/bin/sh", "/entrypoint.sh"]
