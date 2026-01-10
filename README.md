<div align="center" width="100%">

[![Docker Hytale Server](https://repository-images.githubusercontent.com/1129339268/326db70c-ce07-4e0e-a256-fabc1c0216a5)](https://github.com/deinfreu/docker-hytale-server)


[![GitHub stars](https://img.shields.io/github/stars/deinfreu/docker-hytale-server?style=for-the-badge&color=daaa3f)](https://github.com/deinfreu/docker-hytale-server)
[![GitHub last commit](https://img.shields.io/github/last-commit/deinfreu/docker-hytale-server?style=for-the-badge)](https://github.com/deinfreu/docker-hytale-server)
[![Discord](https://img.shields.io/discord/1458149014808821965?style=for-the-badge&label=Discord&labelColor=5865F2)](https://discord.gg/2kn2T6zpaV)
[![Docker Pulls](https://img.shields.io/docker/pulls/freudend/hytale-server?style=for-the-badge)](https://hub.docker.com/r/freudend/hytale-server)
[![Docker Image Size](https://img.shields.io/docker/image-size/freudend/hytale-server/experimental?style=for-the-badge&label=UBUNTU%20SIZE)](https://hub.docker.com/layers/freudend/hytale-server/experimental/images/)
[![Docker Image Size (tag)](https://img.shields.io/docker/image-size/freudend/hytale-server/experimental-alpine?sort=date&style=for-the-badge&label=ALPINE%20SIZE)](https://hub.docker.com/layers/freudend/hytale-server/experimental-alpine/images/)
[![Docker Image Size (tag)](https://img.shields.io/docker/image-size/freudend/hytale-server/experimental-alpine-liberica?sort=date&style=for-the-badge&label=ALPINE%20LIBERICA%20SIZE)](https://hub.docker.com/layers/freudend/hytale-server/experimental-alpine-liberica/images/)
[![GitHub license](https://img.shields.io/github/license/deinfreu/docker-hytale-server?style=for-the-badge)](https://github.com/deinfreu/docker-hytale-server/blob/main/LICENSE)

Deploy a production-ready Hytale server in seconds with automated diagnostics, hardened security, and optimized networking using a single command with docker.

</div>

## 🤝 Support & Resources

* **Documentation:** Detailed performance optimizations and security specifications are located in the [Project Wiki](../../wiki).
* **Troubleshooting:** Consult the [FAQ](../../wiki/FAQ) and our [Security Policy](SECURITY.md) before reporting issues. You can also visit our [Discord](https://discord.com/invite/2kn2T6zpaV)!
* **Issue Tracking:** Can't find what you're looking for? [Open a new issue](issues/new) and I'll be happy to help.

## ⚡️ Quick start

Install docker [CLI](https://docs.docker.com/engine/install/) on linux or the [GUI](https://docs.docker.com/desktop) on windows and macos.

You can run the container by running this in your CLI
```bash
docker run -d \
  --name hytale-server \
  --restart unless-stopped \
  -e EULA="TRUE" \
  -p 5520:5520/udp \
  -v ./data:/home/container \
  freudend/docker-hytale-server:latest
```

Alternatively, you can deploy using Docker Compose. Use the configuration below or explore the [examples](https://github.com/deinfreu/docker-hytale-server/tree/main/examples) folder for more advanced templates.

```bash
services:
  hytale:
    image: freudend/hytale-server:experimental
    container_name: hytale-server
    environment:
      EULA: "TRUE"               
    restart: no
    ports:
      - "5520:5520/udp"
    volumes:
      - ./data:/data                        # Mounts the host's ./data folder to the container's /data directory (host:docker).
      - /etc/localtime:/etc/localtime:ro    # Uses the local time of the host machine
      - /etc/timezone:/etc/timezone:ro      # Uses the local timezone of the host machine
```

That's all you need to know to start! 🎉