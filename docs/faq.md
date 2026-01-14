---
layout: default
title: "❓ FAQ"
nav_order: 5
description: "Frequently Asked Questions for the Hytale Docker Server"
---

# ❓ Frequently Asked Questions

Find solutions to common issues encountered when setting up or managing your Hytale server.

---

## Server requires re-authentication after every restart

This happens because the container does not have access to the host’s Linux hardware ID. Without it, the server generates a new identity on each restart.

### How to fix
In youd docker compose mount this volume: "/etc/machine-id:/etc/machine-id:ro". Or in docker run use -v "/etc/machine-id:/etc/machine-id:ro".

---

## 🕒 My logs don't show the correct date or time.

By default, Docker containers often run in Coordinated Universal Time (UTC). To synchronize the server logs with your local time, you must define the `TZ` (Time Zone) environment variable.

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