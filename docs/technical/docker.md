---
layout: default
title: "Docker"
parent: "⚙️ Technical Info"
nav_order: 2
---

# 🐳 Docker Configuration Reference

The Hytale server container is highly configurable through environment variables. These allow you to tune performance, security, and automation without modifying the internal container files.

## ⚙️ Core Server Settings

| Variable                     | Description                                                                 | Default   |
|------------------------------|-----------------------------------------------------------------------------|-----------|
| `TZ`                         | The [Timezone identifier](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones) for server logs | `UTC`     |
| `DEBUG`                      | Set to `TRUE` to enable diagnostic scripts and verbose logging               | `FALSE`   |
| `SERVER_PORT`                | The primary UDP port for game traffic                                        | `5520`    |
| `SERVER_IP`                  | The IP address the server binds to                                            | `0.0.0.0` |
| `PROD`                       | Set to `TRUE` to run production readiness audits                             | `FALSE`   |
| `JAVA_ARGS`                  | Additional flags for the JVM (expert use only)                               | `(Empty)` |
| `CACHE`                      | Enables the Ahead-Of-Time cache                                              | `FALSE`   |
| `HYTALE_ACCEPT_EARLY_PLUGINS`| Allow loading early or experimental plugins                                  | `FALSE`   |
| `HYTALE_ALLOW_OP`            | Automatically grant operator permissions                                     | `FALSE`   |
| `HYTALE_AUTH_MODE`           | Enable authenticated (online) mode                                           | `FALSE`   |
| `HYTALE_BACKUP`              | Enable automatic backups                                                     | `FALSE`   |
| `HYTALE_BACKUP_FREQUENCY`    | Frequency of automatic backups                                               | `(Empty)` |

---

## ⚙️ Hytale Settings (config.json)

These variables directly inject values into the `home/container/config.json` file on startup.

| Variable | Description | Default |
| :--- | :--- | :--- |
| `HYTALE_SERVER_NAME` | The name displayed in the server browser. | `Hytale Server` |
| `HYTALE_MOTD` | Message of the Day shown to players. | `(Empty)` |
| `HYTALE_PASSWORD` | Set a password to make the server private. | `(Empty)` |
| `HYTALE_MAX_PLAYERS` | Maximum number of concurrent players. | `100` |
| `HYTALE_MAX_VIEW_RADIUS` | Maximum chunk distance sent to clients. | `32` |
| `HYTALE_COMPRESSION` | Enable or disable local network compression. | `false` |
| `HYTALE_WORLD` | The name of the world folder to load. | `default` |
| `HYTALE_GAMEMODE` | The default game mode (e.g., Adventure, Creative). | `Adventure` |

---

## 📂 Volume Mapping (Persistence)

To ensure your world, player data, and configurations are saved when the container restarts, you **must** map a volume to the internal working directory.

| Container Path | Purpose |
| :--- | :--- |
| `/home/container` | Main directory containing world files, logs, and configs. |

## Folder structure

The following folder structure is used: