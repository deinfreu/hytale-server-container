---
layout: default
title: "Unraid"
parent: "Guides"
nav_order: 6
description: "Install the Hytale Server Container on Unraid using the Docker web UI — container setup, machine-id configuration, port mapping, and authentication."
---

# Unraid

Running the Hytale server container on Unraid is straightforward using Docker, which is natively supported.

## Prerequisites

- Unraid OS installed
- A valid Hytale game license for authentication

## Setup via Web UI

1. **Open the Unraid web interface** and navigate to the **Containers** tab.

2. **Add a new container**:
   - **Name**: `hytale-server`
   - **Repository**: `deinfreu/hytale-server:latest-alpine-liberica`
   - **Hostname**: Your server hostname (e.g., `unraid`)

3. **Configure Network**:
   - **Add another Port**: Host port `5520`, Container port `5520`, Protocol `UDP`

4. **Configure Storage**:
   - **Add another Path**:
     - Host path: Your desired data directory (e.g., `/mnt/user/appdata/hytale`)
     - Container path: `/home/container`
     - Mode: `RW`
   - **Add another Path** (machine-id):
     - Host path: Leave blank initially
     - Container path: `/etc/machine-id`
     - Mode: `RO`

5. **Configure Containers**:
   - Toggle **Terminal/PTY** to `ON` (required for authentication)
   - Set Restart policy to `Unless-stopped` or `Always`

6. **Save and apply** the container settings.

## Machine-ID Configuration

Unraid may not persist `/etc/machine-id` reliably across reboots in Docker containers. To ensure persistent server authorization:

1. **SSH into your Unraid server**:

   ```bash
   ssh root@<your-unraid-ip>
   ```

2. **Create a machine-id file** in your Hytale data directory:

   ```bash
   cat /etc/machine-id > /mnt/user/appdata/hytale/machine-id
   ```

3. **Edit the container** in the Unraid web UI and change the machine-id path mapping:
   - Host path: `/mnt/user/appdata/hytale/machine-id`
   - Container path: `/etc/machine-id`
   - Mode: `RO`

4. **Apply changes**.

## Authentication

1. **Start the container** from the Unraid web UI.
2. **Open the console** by clicking on the container name in the Containers tab.
3. The first run will display an authentication URL. Open it in a browser and log in with your Hytale account.
4. After authorization, the server will start. You can now connect from clients.

## Post-Installation

After successful authentication, you may optionally stop the container and configure additional environment variables or mod mounts via the Unraid web UI under **Settings**.

{: .note }
> Keeping Terminal/PTY enabled is recommended for initial setup. You can disable it after authentication if desired.
