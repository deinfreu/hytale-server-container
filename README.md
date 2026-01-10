> **[WARNING]** Still waiting on Hytale to release more information about the server binary. The docker image is therefore under development.

<div align="center" width="100%">

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="https://github.com/deinfreu/docker-hytale-server/blob/experimental/assets/images/logo_Dark.png">
  <source media="(prefers-color-scheme: light)" srcset="https://github.com/deinfreu/docker-hytale-server/blob/experimental/assets/images/logo_Light.png">
  <img alt="Docker Hytale Server Logo" src="https://github.com/deinfreu/docker-hytale-server/blob/experimental/assets/images/logo_Light.png" width="600">
</picture>


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

* **Documentation:** Detailed performance optimizations and security specifications are located in the [Project Wiki](https://deinfreu.github.io/docker-hytale-server/).
* **Troubleshooting:** Consult the [FAQ](https://deinfreu.github.io/docker-hytale-server/faq.html) and our [Security Policy](SECURITY.md) before reporting issues. You can also visit our [Discord](https://discord.com/invite/2kn2T6zpaV)!

## ⚡️ Quick start

Install docker [CLI](https://docs.docker.com/engine/install/) on linux or the [GUI](https://docs.docker.com/desktop) on windows, macos and linux

You can run the container by running this in your CLI
```bash
docker run -d \
  --name hytale-server \
  --restart unless-stopped \
  -e EULA="TRUE" \
  -p 5520:5520/udp \
  -v freudend-docker-hytale-server:/home/container \
  freudend/docker-hytale-server:latest
```

Alternatively, you can deploy using Docker Compose. Use the configuration below or explore the [examples](https://github.com/deinfreu/docker-hytale-server/tree/main/examples) folder for more advanced templates.

```bash
services:
  hytale:
    image: freudend/hytale-server:latest
    container_name: hytale-server
    environment:
      EULA: "TRUE"               
    restart: unless-stopped
    ports:
      - "5520:5520/udp"
    volumes:
      - ./data:/home/container
```

That's all you need to know to start! 🎉