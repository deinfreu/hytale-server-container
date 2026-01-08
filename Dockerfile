# syntax=docker/dockerfile:1.7
FROM eclipse-temurin:25.0.1_8-jre

# Multi-arch support
ARG TARGETOS
ARG TARGETARCH
ARG TARGETVARIANT

ARG SERVER_JAR_URL
ARG SERVER_JAR_SHA256
ENV SERVER_JAR_SHA256=${SERVER_JAR_SHA256}

# Sets the user and home directory for Pterodactyl compatibility.
ENV USER=container
ENV HOME=/home/container

# Metadata
LABEL org.opencontainers.image.title="docker-hytale-server" \
    org.opencontainers.image.description="Minimal Hytale server image optimized for performance, security, and AppArmor" \
    org.opencontainers.image.source="https://github.com/freudend/docker-hytale-server"

# Runtime config
ENV EULA="" \
    SERVER_JAR="" \
    SERVER_IP="" \
    SERVER_JAR_SHA256="" \
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

# 4. bake the jar. We download this to /usr/local/lib/ so it's protected and separate from scripts
ARG SERVER_JAR_URL
ARG SERVER_JAR_SHA256
RUN if [ -n "$SERVER_JAR_URL" ]; then \
    curl -L -o /usr/local/lib/server.jar "$SERVER_JAR_URL" && \
    if [ -n "$SERVER_JAR_SHA256" ]; then \
    echo "$SERVER_JAR_SHA256  /usr/local/lib/server.jar" | sha256sum -c -; \
    fi && \
    chmod 444 /usr/local/lib/server.jar; \
    fi

# 5. Persistent Data
WORKDIR ${HOME}

# 6. Copy Scripts & Fix Line Endings
COPY --chmod=755 scripts/checks/network-check.sh /usr/local/bin/network-check.sh
COPY --chmod=755 scripts/checks/security-check.sh /usr/local/bin/security-check.sh
COPY --chmod=755 scripts/checks/prod-check.sh /usr/local/bin/prod-check.sh
COPY --chmod=755 entrypoint.sh /entrypoint.sh

# Run dos2unix after copying the scripts
RUN dos2unix /usr/local/bin/*.sh

# 7. Finalize
USER ${USER}

# Expose Hytale server port (UDP for QUIC support)
EXPOSE 25565/udp

# Graceful shutdown
STOPSIGNAL SIGTERM

# Healthcheck
# Note: Requires iproute2 (installed in step 1)
HEALTHCHECK --interval=30s --timeout=5s --start-period=2m --retries=3 \
    CMD ss -ulpn | grep -q ":${SERVER_PORT:-25565}" || exit 1

# Build metadata
ARG BUILDTIME=local
ARG VERSION=local
ARG REVISION=local
COPY <<EOF /etc/image.properties
buildtime=${BUILDTIME}
version=${VERSION}
revision=${REVISION}
EOF

# Proper init + startup
ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["/bin/sh", "/entrypoint.sh"]