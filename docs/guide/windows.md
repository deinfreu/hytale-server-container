---
layout: default
title: "Windows"
parent: "Guides"
nav_order: 3
description: "Deploy the Hytale Server Container on Windows using Docker Desktop with WSL2 backend — installation, machine-id setup, and server deployment."
---

# Windows (Docker Desktop)

Running the Hytale server container on Windows requires Docker Desktop. The following guide covers installation and server deployment via Docker Desktop or WSL2 backend.

## Prerequisites

- Windows 10/11 (64-bit)
- Virtualization enabled in BIOS
- A valid Hytale game license for authentication

## Install Docker Desktop

1. **Download Docker Desktop** from [docker.com](https://www.docker.com/products/docker-desktop/) and install it.

2. **Ensure WSL2 backend is enabled**: Open Docker Desktop → Settings → General → "Use the WSL 2 based engine" should be checked.

3. **Verify installation**:

   ```bash
   docker --version
   docker compose version
   ```

## Deploy the Server

1. **Create a project directory**:

   ```powershell
   mkdir hytale-server && cd hytale-server
   ```

2. **Create a `docker-compose.yml`**:

   > [!NOTE]
   > The default `/etc/machine-id` binding works with Docker Desktop's native Linux image but breaks under WSL2. Use the local machine-id approach below for compatibility.

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

3. **Generate a machine-id file**:

   In the same directory, run in PowerShell:

   ```powershell
   [guid]::NewGuid().ToString("N") | Out-File -Encoding ascii -NoNewline .\machine-id
   ```

4. **Start the server**:

   ```bash
   docker compose up
   ```

   The first run will download the Hytale server binary and display an authentication URL in the terminal. Open this link in a browser, log in with your Hytale account, and follow the instructions to authorize the server.

{: .note }
> Run `docker compose up` without the `-d` flag to access the terminal for initial authentication. Once authorized, you can restart with `-d` for background operation.
