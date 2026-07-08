---
layout: default
title: "Guides"
has_children: true
nav_order: 3
description: "Platform-specific deployment guides for the Hytale Server Container on Debian, Raspberry Pi, TrueNAS Scale, Unraid, Windows WSL2, and more."
---

# Guides

Platform-specific tutorials for deploying the Hytale server container. Each guide covers Docker installation, volume configuration, machine-id setup, and authentication steps unique to that platform.

## Available Platforms

- **[Debian 13 (trixie)](./debian.md)** — Full Docker installation from official repository, docker-compose deployment, and first-run authentication on Debian.
- **[Raspberry Pi (ARM64)](./raspberrypi.md)** — Deploy on Raspberry Pi 4+ using QEMU emulation of x86_64 binaries, with performance tips for headless mode.
- **[TrueNAS Scale](./truenas_scale.md)** — Custom app YAML deployment with persistent volume mounts and port configuration for TrueNAS users.
- **[Unraid](./unraid.md)** — Step-by-step setup via the Unraid Docker web UI, including container parameters and console access for authentication.
- **[Windows WSL2](./windows.md)** — Install Docker Desktop with WSL2 backend, configure persistent storage, and run the server on Windows.

## General Notes

All guides assume:
- A valid Hytale game license is available
- Docker or Docker Compose is installed on your system
- You have sufficient permissions to manage containers

Common challenges across platforms include machine-id persistence (prevents re-authentication loops) and granting terminal access for the initial authentication flow. Each guide addresses these platform-specifically.

---

> **Disclaimer:** This project is not affiliated with HYPIXEL STUDIOS CANADA INC. A valid Hytale license is required to download the server binaries.
