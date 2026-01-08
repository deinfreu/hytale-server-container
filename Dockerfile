# syntax=docker/dockerfile:1.7
FROM eclipse-temurin:25.0.1_8-jre

# Multi-arch support
ARG TARGETOS
ARG TARGETARCH
ARG TARGETVARIANT

# Sets the user and home directory for Pterodactyl compatibility.
ENV USER=container
ENV HOME=/home/container

# Metadata
LABEL org.opencontainers.image.title="docker-hytale-server" \
    org.opencontainers.image.description="Minimal Hytale server image optimized for performance, security, and AppArmor" \
    org.opencontainers.image.source="https://github.com/freudend/docker-hytale-server"

# Runtime config
ENV EULA="" \
    AUTO_UPDATE="" \
    SERVER_IP="" \
    SERVER_PORT="" \
    JAVA_OPTS="" \
    UID=1000 \
    GID=1000

# BuildKit mount for platform-specific package installation
ARG EXTRA_DEB_PACKAGES=""
ARG EXTRA_DNF_PACKAGES=""
ARG EXTRA_ALPINE_PACKAGES=""
ARG FORCE_INSTALL_PACKAGES=1

# 1. Install Dependencies (Cached Layer)
# We install dos2unix and iproute2 here so they are ready for later steps
RUN --mount=target=/build,source=build \
    TARGET=${TARGETARCH}${TARGETVARIANT} \
    sh /build/run.sh install-packages

# 2. Add Gosu (Privilege dropping)
COPY --from=tianon/gosu:1.19 /gosu /usr/local/bin/
RUN chmod +x /usr/local/bin/gosu

# 3. Setup User (Cached Layer)
RUN --mount=target=/build,source=build \
    sh /build/run.sh setup-user

# 4. Persistent Data
WORKDIR ${HOME}

# 5. copy over the scripts and the etnrypoint.sh file
COPY scripts/ /usr/local/bin/scripts
COPY entrypoint.sh /entrypoint.sh

# 6. Perform all file operations in one RUN to minimize layers
RUN find /usr/local/bin/scripts -type f -name "*.sh" -exec dos2unix {} + && \
    dos2unix /entrypoint.sh && \
    chmod -R 755 /usr/local/bin/scripts && \
    chmod +x /entrypoint.sh

# 7. Finalize switch to user to get out of root.
USER ${USER}

# 8. Expose Hytale server port (UDP for QUIC support)
EXPOSE 25565/udp
EXPOSE 25565/tcp

# 9. Graceful shutdown
STOPSIGNAL SIGTERM

# 10. Healthcheck
# Note: Requires iproute2 (installed in step 1)
HEALTHCHECK --interval=30s --timeout=5s --start-period=2m --retries=3 \
    CMD ss -ulpn | grep -q ":${SERVER_PORT:-25565}" || exit 1

# 11. Build metadata
ARG BUILDTIME=local
ARG VERSION=local
ARG REVISION=local
COPY <<EOF /etc/image.properties
buildtime=${BUILDTIME}
version=${VERSION}
revision=${REVISION}
EOF

# 12. FINAL Proper init + startup
ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["/bin/sh", "/entrypoint.sh"]