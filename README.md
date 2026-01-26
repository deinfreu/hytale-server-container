> **[INFO]** This Docker container is functioning properly. Clear your browser cache when visiting the [docs](https://shotah.github.io/hytale-server-container/) to ensure you see the latest version of the manual.

<div align="center" width="100%">

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="https://github.com/shotah/hytale-server-container/blob/main/assets/images/logo_Dark.png">
  <source media="(prefers-color-scheme: light)" srcset="https://github.com/shotah/hytale-server-container/blob/main/assets/images/logo_Light.png">
  <img alt="Docker Hytale Server Logo" src="https://github.com/shotah/hytale-server-container/blob/main/assets/images/logo_Light.png" width="600">
</picture>

[![GitHub stars](https://img.shields.io/github/stars/shotah/hytale-server-container?style=for-the-badge&color=daaa3f)](https://github.com/shotah/hytale-server-container)
[![GitHub last commit](https://img.shields.io/github/last-commit/shotah/hytale-server-container?style=for-the-badge)](https://github.com/shotah/hytale-server-container)
[![Docker Pulls](https://img.shields.io/docker/pulls/shotah/hytale-server?style=for-the-badge)](https://hub.docker.com/r/shotah/hytale-server)
[![Docker Image Size](https://img.shields.io/docker/image-size/shotah/hytale-server/experimental?style=for-the-badge&label=UBUNTU%20SIZE)](https://hub.docker.com/layers/shotah/hytale-server/experimental/images/)
[![Docker Image Size (tag)](https://img.shields.io/docker/image-size/shotah/hytale-server/experimental-alpine?sort=date&style=for-the-badge&label=ALPINE%20SIZE)](https://hub.docker.com/layers/shotah/hytale-server/experimental-alpine/images/)
[![Docker Image Size (tag)](https://img.shields.io/docker/image-size/shotah/hytale-server/experimental-alpine-liberica?sort=date&style=for-the-badge&label=ALPINE%20LIBERICA%20SIZE)](https://hub.docker.com/layers/shotah/hytale-server/experimental-alpine-liberica/images/)
[![GitHub license](https://img.shields.io/github/license/shotah/hytale-server-container?style=for-the-badge)](https://github.com/shotah/hytale-server-container/blob/main/LICENSE)

Deploy a production-ready Hytale server in seconds with automated diagnostics, hardened security, and optimized networking using a single command with docker.

</div>

## 🤝 Support & Resources

* **Documentation:** Detailed performance optimizations and security specifications are located in the [Project Docs](https://shotah.github.io/hytale-server-container/).
* **Troubleshooting:** Consult the [FAQ](https://shotah.github.io/hytale-server-container/faq.html) and our [Security Policy](SECURITY.md) before reporting issues.

## ⚡️ Quick start

Install docker [CLI](https://docs.docker.com/engine/install/) on linux or the [GUI](https://docs.docker.com/desktop) on windows, macos and linux

You can run the container by running this in your CLI

```bash
docker run \
  --name hytale-server \
  -e SERVER_IP="0.0.0.0" \
  -e SERVER_PORT="5520" \
  -e PROD="FALSE" \
  -e DEBUG="FALSE" \
  -e TZ="UTC" \
  -p 5520:5520/udp \
  -v "hytale-server:/home/container" \
  -v "/etc/machine-id:/etc/machine-id:ro" \
  --restart unless-stopped \
  -t -i \
  shotah/hytale-server:experimental-alpine
```

Alternatively, you can deploy using Docker Compose. Use the configuration below or explore the [examples](https://github.com/shotah/hytale-server-container/tree/main/examples) folder for more advanced templates.

```yaml
services:
  hytale:
    image: shotah/hytale-server:experimental-alpine
    container_name: hytale-server
    environment:
      SERVER_IP: "0.0.0.0"
      SERVER_PORT: "5520"
      PROD: "FALSE"
      DEBUG: "FALSE"
      TZ: "UTC"
    restart: unless-stopped
    ports:
      - "5520:5520/udp"
    volumes:
      - ./data:/home/container
      - /etc/machine-id:/etc/machine-id:ro
    tty: true
    stdin_open: true
```

## 🎮 Pre-release Server

To run a pre-release version of the Hytale server, set the `HYTALE_PATCHLINE` environment variable:

```yaml
environment:
  HYTALE_PATCHLINE: "pre-release"  # Options: "release" (default), "pre-release"
```

## 📦 CurseForge Mod Support

Automatically download mods from CurseForge on startup using the `CURSEFORGE_MOD_IDS` environment variable:

```yaml
environment:
  CURSEFORGE_MOD_IDS: "1423494,1430352"  # Comma-separated mod project IDs
```

Find mod IDs in the CurseForge URL: `https://www.curseforge.com/hytale/mods/mod-name/12345` → ID is `12345`

The downloader:
- Fetches the latest version automatically
- Tracks installed mods via manifest
- Cleans up removed mods on restart

## ⚙️ Environment Variables

### Server Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `SERVER_IP` | `0.0.0.0` | IP address to bind the server |
| `SERVER_PORT` | `5520` | UDP port for the server |
| `TZ` | `UTC` | Timezone for logs |
| `DEBUG` | `FALSE` | Enable debug logging and security audits |
| `PROD` | `FALSE` | Enable production mode checks |

### Hytale Server Config (`config.json`)

These environment variables override settings in `config.json`:

| Variable | Default | Description |
|----------|---------|-------------|
| `HYTALE_SERVER_NAME` | `Hytale Server` | Server name shown in server list |
| `HYTALE_MOTD` | *(empty)* | Message of the day |
| `HYTALE_PASSWORD` | *(empty)* | Server password (leave empty for public) |
| `HYTALE_MAX_PLAYERS` | `100` | Maximum concurrent players |
| `HYTALE_MAX_VIEW_RADIUS` | `32` | View distance in chunks |
| `HYTALE_COMPRESSION` | `false` | Enable local compression |
| `HYTALE_WORLD` | `default` | Default world name |
| `HYTALE_GAMEMODE` | `Adventure` | Default game mode |

### Access Control

| Variable | Default | Description |
|----------|---------|-------------|
| `HYTALE_WHITELIST_ENABLED` | `false` | Enable whitelist mode |
| `HYTALE_WHITELIST` | *(empty)* | Comma-separated player UUIDs to whitelist |
| `HYTALE_OPS` | *(empty)* | Comma-separated player UUIDs to grant OP |

### Patchline & Mods

| Variable | Default | Description |
|----------|---------|-------------|
| `HYTALE_PATCHLINE` | `release` | Server version: `release` or `pre-release` |
| `CURSEFORGE_MOD_IDS` | *(empty)* | Comma-separated CurseForge mod project IDs |
| `HYTALE_MOD_DIR` | `/home/container/mods` | Directory for mods |

### Volume Mounts

For custom configuration files, mount them directly:

```yaml
volumes:
  - ./data:/home/container           # Server data (required)
  - ./my-config.json:/home/container/config.json        # Custom config
  - ./my-whitelist.json:/home/container/whitelist.json  # Custom whitelist
  - ./my-permissions.json:/home/container/permissions.json  # Custom permissions
  - /etc/machine-id:/etc/machine-id:ro  # Machine ID for auth
```

## 🔧 Common Fixes & Troubleshooting

If you encounter issues during deployment, check these common solutions below.

### 1. Authentication Problems

If the server requires authentication or you see authentication errors in the logs, follow these steps in your Linux console:

1. Attach to the running container:
```bash
docker attach [container name]
```


2. Run the authentication command:
```bash
auth login device
```


3. An authentication link will appear. Copy the verification code, paste it into the Hytale OAuth website, and login with your Hytale account. Your server should now start successfully.

### 2. Linux Permission Errors

If the container crashes or logs errors regarding file access, it is likely a permission issue with your mounted volume.

1. **Test with full permissions:** Try setting full permissions on the data directory to verify if this solves the issue.
```bash
chmod -R 777 [volume folder]
```


2. **Secure the permissions:** If the server runs successfully after step 1, revert to safer permissions to secure your server.
```bash
chmod -R 644 [volume folder]
```


3. **Directory navigation issues:** If setting permissions to `644` prevents folder navigation or access, you may need to use `755` for directories specifically.
```bash
chmod -R 755 [volume folder]
```

That's all you need to know to start! 🎉

## 🙏 Credits & Acknowledgments

This project is a fork of the excellent work by **[deinfreu](https://github.com/deinfreu)**:

- **Original Repository:** [deinfreu/hytale-server-container](https://github.com/deinfreu/hytale-server-container)
- **Original Author:** [@deinfreu](https://github.com/deinfreu)

Thank you to deinfreu and all the [original contributors](https://github.com/deinfreu/hytale-server-container/graphs/contributors) for building the foundation of this container. This fork adds additional features like pre-release server support (`HYTALE_PATCHLINE`) and CurseForge mod downloading (`CURSEFORGE_MOD_IDS`).
