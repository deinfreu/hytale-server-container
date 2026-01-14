---
layout: default
title: "Hytale"
parent: "⚙️ Technical Info"
nav_order: 1
---

# Hytale specific settings

Here you can find the hytale specific settings

---

### Hytale downloader CLI tool

You can interface with this tool by entering your docker terminal. More information [here](../installation/container_installation.md).

You can use the following commands:

| Command                                      | Description                                      |
|---------------------------------------------|--------------------------------------------------|
| hytale-downloader                            | Download the latest release                      |
| hytale-downloader -print-version             | Show game version without downloading            |
| hytale-downloader -version                   | Show hytale-downloader version                   |
| hytale-downloader -check-update              | Check for hytale-downloader updates               |
| hytale-downloader -patchline pre-release     | Download from pre-release channel                |
| hytale-downloader -skip-update-check         | Skip automatic update check                      |

### Hytale server variables

Check the variables in the [docker technical page](./docker.md) which you can use to set server settings 