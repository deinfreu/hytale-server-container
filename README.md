<div align="center" width="100%">

[![GitHub stars](https://img.shields.io/github/stars/deinfreu/hytale-server-container?style=for-the-badge&color=daaa3f)](https://github.com/deinfreu/hytale-server-container)
[![Docker Pulls](https://img.shields.io/docker/pulls/deinfreu/hytale-server?style=for-the-badge&label=PULLS)](https://hub.docker.com/r/deinfreu/hytale-server)
[![Size (tag)](https://img.shields.io/docker/image-size/deinfreu/hytale-server/latest-alpine-liberica?sort=date&style=for-the-badge&label=SIZE)](https://hub.docker.com/layers/deinfreu/hytale-server/latest-alpine-liberica/images/)
[![GitHub license](https://img.shields.io/github/license/deinfreu/hytale-server-container?style=for-the-badge)](https://github.com/deinfreu/hytale-server-container/blob/main/LICENSE)
[![Discord](https://img.shields.io/discord/1458149014808821965?style=for-the-badge&label=Discord&labelColor=5865F2)](https://discord.gg/M8yrdnHb32)

Simply use the docker run command or docker compose, follow the authentication steps in the terminal, and your server will be ready in seconds. Designed by a community of 10+ contributors, this image prioritizes stability, security, and performance, allowing you to focus on managing your world rather than debugging your environment.

</div>

> [!WARNING]
> **A valid Hytale game license is required for container authorization.**
>
> On the first launch, the server will display an authentication URL in your terminal. Open this link in your browser, log in with your Hytale account, and follow the instructions to authorize the server.

## Quick start

### Docker run

> [!TIP]
> container image: "alpine-liberica" provides the smallest footprint and fastest startup time.

```bash
docker run \
  --name hytale-server \
  -p 5520:5520/udp \
  -v "hytale-server:/home/container" \
  -v "/etc/machine-id:/etc/machine-id:ro" \
  --restart unless-stopped \
  deinfreu/hytale-server:latest
```

### Docker compose

> [!IMPORTANT]
> You need to run ```docker compose up``` without the "-d" flag for terminal-based authorization.

```bash
services:
  hytale:
    image: deinfreu/hytale-server:latest
    container_name: hytale-server
    restart: unless-stopped
    ports:
      - "5520:5520/udp"
    volumes:
      - ./data:/home/container
      - /etc/machine-id:/etc/machine-id:ro
    tty: true
    stdin_open: true
```

For additional deployment configurations, see our [examples](https://github.com/deinfreu/hytale-server-container/tree/main/examples) or refer to the [installation](https://hytale-server-container.com/installation/container_installation/?utm_source=github&utm_medium=social&utm_campaign=github_readme) and [OS-specific](https://hytale-server-container.com/guide/?utm_source=github&utm_medium=social&utm_campaign=github_readme) guides.

## Support & Resources

**Support:** 
- OS Specific installation guide at [hytale-server-container.com/guide](https://hytale-server-container.com/guide/?utm_source=github&utm_medium=social&utm_campaign=github_readme).
- Full installation guide available at [hytale-server-container.com/installation](https://hytale-server-container.com/installation/?utm_source=github&utm_medium=social&utm_campaign=github_readme).
- Enviroment variables and more: [hytale-server-container.com/technical](https://hytale-server-container.com/technical/?utm_source=github&utm_medium=social&utm_campaign=github_readme).

**Troubleshooting:**
- For frequently asked questions: [hytale-server-container.com/faq](https://hytale-server-container.com/faq/?utm_source=github&utm_medium=social&utm_campaign=github_readme)
- Join our community and ask your question! [Discord Community](https://discord.com/invite/M8yrdnHb32?utm_source=github&utm_medium=social&utm_campaign=github_readme)
- To check what is actively happening to this github repo and what is planned [GitHub Issues](https://github.com/deinfreu/hytale-server-container/issues?utm_source=github&utm_medium=social&utm_campaign=github_readme)