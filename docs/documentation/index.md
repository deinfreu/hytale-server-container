---
layout: default
title: "Documentation"
has_children: true
nav_order: 4
description: "Technical documentation for the Hytale Server Container — Docker configuration reference, Hytale CLI tool usage, development setup, and server internals."
---

# Documentation

Reference materials covering Docker configuration, the `hytale-downloader` CLI tool, environment variables, and local development setup.

## Topics

- **[Docker Configuration](./docker.md)** — Complete environment variable reference (port, game mode, compression, backups, caching), volume mapping, config.json injection, and image variants (`latest`, `latest-alpine`, `latest-alpine-liberica`).
- **[Hytale Server](./hytale.md)** — The built-in `hytale-downloader` CLI tool: commands for downloading binaries, checking versions, switching to pre-release channel, and performing in-game updates.
- **[Development Setup](./development.md)** — Build Docker images from source, run the Jekyll documentation site locally with Ruby or Docker, and contribute code changes.

## Quick Reference

### Recommended Image

`deinfreu/hytale-server:latest-alpine-liberica` — 61.7MB, Liberica JDK, recommended for all production deployments.

---

> **Disclaimer:** This project is not affiliated with HYPIXEL STUDIOS CANADA INC. A valid Hytale license is required to download the server binaries.
