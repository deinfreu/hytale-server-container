---
layout: default
title: "Raspberry Pi"
parent: "Guides"
nav_order: 4
description: "Deploy the Hytale Server Container on Raspberry Pi (ARM64) using QEMU emulation — Docker setup, machine-id configuration, and performance tips."
---

# Raspberry Pi (ARM64)

The container supports ARM64 architecture via QEMU emulation of the x86_64 Hytale server binary. This guide covers installation and deployment on a Raspberry Pi 4 or newer.

## Prerequisites

- Raspberry Pi 4 or newer with minimum **4GB RAM**
- **Raspberry Pi OS (64-bit)** installed — download from [raspberrypi.com](https://www.raspberrypi.com/software/)
- A valid Hytale game license for authentication

## Install Docker

1. **Install Docker** using the convenience script:

   ```bash
   curl -fsSL https://get.docker.com | sudo sh
   ```

2. **Add your user to the `docker` group** (avoids needing `sudo`):

   ```bash
   sudo usermod -aG docker $USER
   ```

   Log out and back in for the group change to take effect.

3. **Verify installation**:

   ```bash
   docker --version
   docker compose version
   ```

## Deploy the Server

1. **Create a project directory** and navigate into it:

   ```bash
   mkdir hytale-server && cd hytale-server
   ```

2. **Generate a persistent `machine-id`**:

   Raspberry Pi OS may regenerate `/etc/machine-id` across reboots, which breaks server authorization. Instead of binding the system file directly, create a local copy:

   ```bash
   cat /etc/machine-id > ./machine-id
   ```

3. **Create a `docker-compose.yml`**:

   Use the local `machine-id` file in your volumes to ensure consistent authentication across reboots:

   ```yaml
   services:
     hytale:
       image: deinfreu/hytale-server:latest-alpine-liberica
       container_name: hytale-server
       restart: unless-stopped
       ports:
         - "5520:5520/udp"
       volumes:
         - ./data:/home/container
         - ./machine-id:/etc/machine-id:ro
       tty: true
       stdin_open: true
   ```

4. **Start the server**:

   ```bash
   docker compose up
   ```

   The first run will download the Hytale server binary and display an authentication URL in the terminal. Open this link in a browser, log in with your Hytale account, and follow the instructions to authorize the server.

{: .note }
> Run `docker compose up` **without** the `-d` flag for the initial run — you need terminal access to complete the authorization. Once authorized, you can restart with `-d` for background operation: `docker compose up -d`.

## Performance Notes

- The Hytale server binary is x86_64; on ARM64 it runs via **QEMU emulation**, which adds overhead. Expect slower download and startup times compared to native x86_64.
- Use the `latest-alpine-liberica` tag for the smallest image size (~61.7MB).
- Ensure your Pi has a dedicated 4GB RAM allocation — running with a desktop environment is not recommended.

{: .note }
> For best performance, run headless Raspberry Pi OS (no desktop environment). You can install it via `sudo raspi-config` → System Settings → Desktop / CLI → Select **Console**.
