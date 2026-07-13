---
layout: default
title: "Hytale Settings"
parent: "Documentation"
nav_order: 1
description: "Manage Hytale server binaries and updates using the built-in hytale-downloader CLI tool — commands, version checks, pre-release channel, and update instructions."
---

# Hytale specific settings

Here you can find the Hytale-specific settings and tools.

---

## Hytale Downloader CLI Tool

The container includes a built-in `hytale-downloader` tool for managing server binaries and updates. You run it directly inside the running container's terminal.

### Accessing the Container Terminal

**Docker Run:**

```bash
docker exec -it <container_name> /bin/sh
```

Once inside, you can type commands directly.

### Available Commands

| Command | Description |
| --- | --- |
| `hytale-downloader` | Download the latest release |
| `hytale-downloader -print-version` | Show game version without downloading |
| `hytale-downloader -version` | Show hytale-downloader version |
| `hytale-downloader -check-update` | Check for hytale-downloader updates |
| `hytale-downloader -patchline pre-release` | Download from the pre-release channel |
| `hytale-downloader -skip-update-check` | Skip automatic update check |

### Example Usage

```sh
/ # hytale-downloader -print-version
Hytale version: 0.120.0

/ # hytale-downloader
[INFO] Downloading latest release...
[INFO] Update complete. Restart the container to apply.
```

## Updating the Hytale Server

To update your server to the latest version:

1. Open the container terminal as shown above.
2. Type `hytale-downloader` and press Enter.
3. Wait for the download to complete.
4. Restart the container (`docker compose restart` or `docker restart hytale-server`).

The update replaces only server binaries — your configs, worlds, and mods are preserved.

## Hytale Server Variables

For environment variables that configure server behavior (player limits, game mode, authentication, etc.), see the [Docker Configuration Reference](./docker.md).
