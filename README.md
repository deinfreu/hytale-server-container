> **[INFO]** This Docker container is functioning properly. Clear your browser cache when visiting the [docs](https://deinfreu.github.io/hytale-server-container/) to ensure you see the latest version of the manual.

<div align="center" width="100%">

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="https://github.com/deinfreu/hytale-server-container/blob/main/assets/images/logo_Dark.png">
  <source media="(prefers-color-scheme: light)" srcset="https://github.com/deinfreu/hytale-server-container/blob/main/assets/images/logo_Light.png">
  <img alt="Docker Hytale Server Logo" src="https://github.com/deinfreu/hytale-server-container/blob/main/assets/images/logo_Light.png" width="600">
</picture>

[![GitHub stars](https://img.shields.io/github/stars/deinfreu/hytale-server-container?style=for-the-badge&color=daaa3f)](https://github.com/deinfreu/hytale-server-container)
[![GitHub last commit](https://img.shields.io/github/last-commit/deinfreu/hytale-server-container?style=for-the-badge)](https://github.com/deinfreu/hytale-server-container)
[![Discord](https://img.shields.io/discord/1458149014808821965?style=for-the-badge&label=Discord&labelColor=5865F2)](https://discord.gg/M8yrdnHb32)
[![Docker Pulls](https://img.shields.io/docker/pulls/deinfreu/hytale-server?style=for-the-badge)](https://hub.docker.com/r/deinfreu/hytale-server)
[![Docker Image Size](https://img.shields.io/docker/image-size/deinfreu/hytale-server/experimental?style=for-the-badge&label=UBUNTU%20SIZE)](https://hub.docker.com/layers/deinfreu/hytale-server/experimental/images/)
[![Docker Image Size (tag)](https://img.shields.io/docker/image-size/deinfreu/hytale-server/experimental-alpine?sort=date&style=for-the-badge&label=ALPINE%20SIZE)](https://hub.docker.com/layers/deinfreu/hytale-server/experimental-alpine/images/)
[![Docker Image Size (tag)](https://img.shields.io/docker/image-size/deinfreu/hytale-server/experimental-alpine-liberica?sort=date&style=for-the-badge&label=ALPINE%20LIBERICA%20SIZE)](https://hub.docker.com/layers/deinfreu/hytale-server/experimental-alpine-liberica/images/)
[![GitHub license](https://img.shields.io/github/license/deinfreu/hytale-server-container?style=for-the-badge)](https://github.com/deinfreu/hytale-server-container/blob/main/LICENSE)

Deploy a production-ready Hytale server in seconds with automated diagnostics, hardened security, and optimized networking using a single command with docker.

</div>

## 🤝 Support & Resources

* **Documentation:** Detailed performance optimizations and security specifications are located in the [Project Docs](https://deinfreu.github.io/hytale-server-container/?utm_source=github&utm_medium=social&utm_campaign=github_readme).
* **Troubleshooting:** Consult the [FAQ](https://deinfreu.github.io/hytale-server-container/faq.html/?utm_source=github&utm_medium=social&utm_campaign=github_readme) and our [Security Policy](SECURITY.md) before reporting issues. You can also visit our [Discord](https://discord.com/invite/2kn2T6zpaV)

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
  -e TZ="Europe/Amsterdam" \
  -p 5520:5520/udp \
  -v "hytale-server:/home/container" \
  -v "/etc/machine-id:/etc/machine-id:ro" \
  --restart unless-stopped \
  -t -i \
  deinfreu/hytale-server:experimental
```

Alternatively, you can deploy using Docker Compose. Use the configuration below or explore the [examples](https://github.com/deinfreu/hytale-server-container/tree/main/examples) folder for more advanced templates.

```bash
services:
  hytale:
    image: deinfreu/hytale-server:experimental
    container_name: hytale-server
    environment:
      SERVER_IP: "0.0.0.0"
      SERVER_PORT: "5520"
      PROD: "FALSE"
      DEBUG: "FALSE"
      TZ: "Europe/Amsterdam"
    restart: unless-stopped
    ports:
      - "5520:5520/udp"
    volumes:
      - ./data:/home/container
      - /etc/machine-id:/etc/machine-id:ro
    tty: true
    stdin_open: true
```

If you prefer, you can also deploy using Podman Quadlets, e.g. by following this example:

`~/.config/containers/systemd/default.network`
```ini
[Network]
NetworkDeleteOnStop=true

[Install]
WantedBy=default.target
```

`~/.config/containers/systemd/hytale.container`
```ini
[Service]
Description=Hytale Quadlet

[Container]
ContainerName=hytale
EnvironmentFile=%h/.config/containers/systemd/hytale.env
Image=docker.io/deinfreu/hytale-server:experimental
AutoUpdate=registry
Network=default.network
PublishPort=5520:5520/udp
Volume=%h/files/hytale:/home/container
Volume=/etc/machine-id:/etc/machine-id:ro
# If running on an OS with SELinux, use these Volume declarations instead
#Volume=%h/files/hytale:/home/container:z
#Volume=/etc/machine-id:/etc/machine-id:z,ro

[Install]
WantedBy=default.target
```

`~/.config/containers/systemd/hytale.env`
```ini
SERVER_IP=0.0.0.0
SERVER_PORT=5520
PROD=FALSE
DEBUG=FALSE
TZ=Europe/Amsterdam
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
