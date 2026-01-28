<div align="center" width="100%">

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="https://github.com/deinfreu/hytale-server-container/blob/main/assets/images/logo_Dark.png">
  <source media="(prefers-color-scheme: light)" srcset="https://github.com/deinfreu/hytale-server-container/blob/main/assets/images/logo_Light.png">
  <img alt="Docker Hytale Server Logo" src="https://github.com/deinfreu/hytale-server-container/blob/main/assets/images/logo_Light.png" width="800">
</picture>

[![GitHub stars](https://img.shields.io/github/stars/deinfreu/hytale-server-container?style=for-the-badge&color=daaa3f)](https://github.com/deinfreu/hytale-server-container)
[![GitHub last commit](https://img.shields.io/github/last-commit/deinfreu/hytale-server-container?style=for-the-badge)](https://github.com/deinfreu/hytale-server-container)
[![Discord](https://img.shields.io/discord/1458149014808821965?style=for-the-badge&label=Discord&labelColor=5865F2)](https://discord.gg/M8yrdnHb32)
[![Docker Pulls](https://img.shields.io/docker/pulls/deinfreu/hytale-server?style=for-the-badge)](https://hub.docker.com/r/deinfreu/hytale-server)
[![Docker Image Size (tag)](https://img.shields.io/docker/image-size/deinfreu/hytale-server/latest-alpine-liberica?sort=date&style=for-the-badge&label=ALPINE%20LIBERICA%20SIZE)](https://hub.docker.com/layers/deinfreu/hytale-server/latest-alpine-liberica/images/)
[![GitHub license](https://img.shields.io/github/license/deinfreu/hytale-server-container?style=for-the-badge)](https://github.com/deinfreu/hytale-server-container/blob/main/LICENSE)

Deploy a stable Hytale dedicated server with a community-focused Docker image maintained by 10+ contributors. This project simplifies Hytale self-hosting by combining optimized networking with built-in security and debugging tools. Join our active Discord for direct support and to connect with other server owners. Whether you're testing mods or running a persistent world, this container provides a consistent, production-ready environment in one command.

</div>

## Support & Resources

* **Documentation:** Detailed performance optimizations and security specifications are located in the [Project Docs](https://hytale-server-container.com/?utm_source=github&utm_medium=social&utm_campaign=github_readme).
* **Troubleshooting:** Consult the [FAQ](https://hytale-server-container.com/faq.html/?utm_source=github&utm_medium=social&utm_campaign=github_readme) and our [Security Policy](SECURITY.md) before reporting issues. You can also visit our [Discord](https://discord.com/invite/2kn2T6zpaV)

## Quick start

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
  deinfreu/hytale-server:latest
```

Alternatively, you can deploy using Docker Compose. Use the configuration below or explore the [examples](https://github.com/deinfreu/hytale-server-container/tree/main/examples) folder for more advanced templates.

```bash
services:
  hytale:
    image: deinfreu/hytale-server:latest
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