---
layout: default
title: "Debian 13 (trixie)"
parent: "Guides"
nav_order: 5
description: "Deploy the Hytale Server Container on Debian 13 (trixie) — Docker installation, docker-compose setup, and server authentication."
---

# Debian 13 (trixie)

Running the Hytale server container on Debian 13 is straightforward. The following guide covers Docker installation and server deployment.

## Prerequisites

- Debian 13 (trixie) installed (64-bit recommended)
- Root or sudo access
- A valid Hytale game license for authentication

## Install Docker

1. **Update system packages**:

   ```bash
   apt update && apt upgrade -y
   ```

2. **Install Docker** using the official repository:

   ```bash
   apt install -y ca-certificates curl gnupg
   install -m 0755 -d /etc/apt/keyrings
   curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
   chmod a+r /etc/apt/keyrings/docker.gpg

   echo \
     "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
     $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
     tee /etc/apt/sources.list.d/docker.list > /dev/null

   apt update
   apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
   ```

3. **Verify Docker installation**:

   ```bash
   docker --version
   docker compose version
   ```

## Deploy the Server

1. **Create a project directory**:

   ```bash
   mkdir -p ~/hytale-server && cd ~/hytale-server
   ```

2. **Create a `docker-compose.yml`**:

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
         - /etc/machine-id:/etc/machine-id:ro
       tty: true
       stdin_open: true
   ```

3. **Start the server**:

   ```bash
   docker compose up
   ```

   The first run will download the Hytale server binary and display an authentication URL in the terminal. Open this link in a browser, log in with your Hytale account, and follow the instructions to authorize the server.

{: .note }
> Run `docker compose up` without the `-d` flag to access the terminal for initial authentication. Once authorized, you can restart with `-d` for background operation.
