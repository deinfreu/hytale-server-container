# Security Policy

## Security Measures in this Image
This image is built with a "Security-First" mindset to protect both the game server data and the host system.

1. **Non-Root Execution**: The container runs as the `container` user (UID 1000) by default. Even if an attacker gains control of the Hytale process, they do not have root access to the container or the host.
2. **Zombie Process Protection**: We use `tini` as the init system. This ensures that the Java process is managed correctly, signals (like `SIGTERM`) are handled gracefully, and "zombie" processes are reaped to prevent resource exhaustion.
3. **Audit Scripts**: The image includes pre-flight audit scripts (`security-check.sh`, `network-check.sh`) that run on every boot to detect common misconfigurations before the server starts.
4. **Minimal Attack Surface**: Based on `eclipse-temurin` (JRE), we exclude unnecessary build tools, compilers, and shells where possible to reduce the footprint for potential exploits.
5. **Read-Only Integrity**: The server JAR is stored in `/usr/local/lib/` with `444` (read-only) permissions to prevent runtime modification of the server core.

## Reporting a Vulnerability

**Please follow these steps to report security issues:**

* **Submit a Private Advisory**: Please report security issues to [https://github.com/deinfreu/hytale-server-container/security/advisories/new](https://github.com/deinfreu/hytale-server-container/security/advisories/new).
* **Alert the Maintainer**: Please also create an empty security issue to alert me, as GitHub Advisories do not send a notification; I probably will miss it without this: [Submit Alert Issue](https://github.com/deinfreu/hytale-server-container/issues/new?assignees=&labels=security&template=security_alert.md).
* **No Automated Scans**: Do not report any upstream dependency issues or scan results by any tools. It will be closed immediately without explanation. Unless you have a **Proof of Concept (PoC)** to prove that the upstream issue actually affects this Hytale server image.
* **Keep it Private**: Do not use the public issue tracker or discuss it in public as it will cause more damage.

## Best Practices for Deployment

### 1. Resource Limits (DoS Protection)
Always run this container with memory and CPU limits to prevent a rogue Hytale process from crashing your host.
* **Docker Compose**: Use `deploy.resources.limits`.
* **Pterodactyl**: Set the limits in the "Build Configuration" tab.

### 2. Network Isolation
* **Do not use `--network host`**. Use the default bridge or a custom Docker network.
* Only expose the necessary ports (default `5520/udp` for Hytale and `5520/tcp` for legacy/proxies).

### 3. Filesystem Security
* Mount your local volume to `/home/container`. 
* Ensure the host directory is owned by UID `1000` to avoid needing `sudo` or root privileges within the container.

### 4. Keep Images Updated
We regularly rebuild this image to include the latest JRE security patches. Enable automated updates or periodically pull the latest tag:
```bash
docker pull ghcr.io/deinfreu/hytale-server-container:latest
```
