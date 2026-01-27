---
layout: default
title: "❓ FAQ"
nav_order: 6
description: "Frequently Asked Questions for the Hytale Docker Server"
---

# ❓ Frequently Asked Questions

Find solutions to common issues encountered when setting up or managing your Hytale server.

---

## How can I update the Hytale server to the latest version?

{: .warning }
> Create a backup of your server files before performing an update to prevent data loss.

1. Run the following command to access the terminal inside your container:

  ```bash
  docker exec -it hytale-server /bin/sh
  ```

2. Run the `hytale-downloader` CLI tool:

  ```bash
  hytale-downloader
  ```

3. Restart the Docker container, and the script will automatically install the new files.

---

## How can I give myself permissions in-game?

You can attach to the server console using the following command:

{: .note }
> Enable interactive mode by setting `tty: true` and `stdin_open: true` in your docker compose file, or use `docker run -it` for interactive access.

```bash
docker attach CONTAINER_NAME
```

Once attached, use the following command to give yourself operator status:

```bash
/op add USERNAME
```

---

## Server requires re-authentication after every restart

This happens because the container does not have access to the host’s Linux hardware ID. Without it, the server generates a new identity on each restart.

### How to fix
Mount the machine-id volume in your Docker Compose file: `"/etc/machine-id:/etc/machine-id:ro"`. For Docker run, use `-v "/etc/machine-id:/etc/machine-id:ro"`.

---

## I can't run the server on ARM64

The `hytale-downloader` CLI tool does not yet support ARM64.

### How to fix
Currently waiting for Hytale to release the ARM64 version of this tool. See the announcement [here](https://x.com/slikey/status/2010869532454510999).

---

## My logs don't show the correct date or time

By default, Docker containers run in Coordinated Universal Time (UTC). To synchronize the server logs with your local time, define the `TZ` (Time Zone) environment variable.

### How to Fix
1.  Consult the [List of TZ Database Time Zones](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones).
2.  Locate your location in the **"TZ identifier"** column (e.g., `America/New_York` or `Europe/Paris`).
3.  Add the variable to your deployment:

#### Docker CLI
```bash
docker run -e TZ="Europe/Brussels" ...
```
#### Docker Compose
```bash
services:
  hytale:
    environment:
      - TZ=Europe/Brussels
```
