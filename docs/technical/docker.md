---
layout: default
title: "Docker"
parent: "⚙️ Technical Info"
nav_order: 2
---

# 🐳 Docker Configuration Reference

The Hytale server container is highly configurable through environment variables. These allow you to tune performance, security, and automation without modifying the internal container files.

## ⚙️ Core Server Settings

| Variable                      | Description                                                                                             | Default    |
|-------------------------------|---------------------------------------------------------------------------------------------------------|------------|
| `TZ`                          | The [Timezone identifier](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones) for server logs | `UTC`      |
| `DEBUG`                       | Set to `TRUE` to enable diagnostic scripts and verbose logging                                          | `FALSE`    |
| `SERVER_PORT`                 | The primary UDP port for game traffic                                                                   | `5520`     |
| `SERVER_IP`                   | The IP address the server binds to                                                                      | `0.0.0.0`  |
| `PROD`                        | Set to `TRUE` to run production readiness audits                                                        | `FALSE`    |
| `JAVA_ARGS`                   | Additional flags for the JVM (expert use only)                                                          | `(Empty)`  |

---

## 📥 Hytale Downloader Options

| Variable                      | Description                                                                                             | Default    |
|-------------------------------|---------------------------------------------------------------------------------------------------------|------------|
| `HYTALE_PATCHLINE`            | Patchline to download from: `release` or `prerelease`                                                   | `release`  |
## 📦 CurseForge Mod Downloader

Automatically download and manage mods from CurseForge.

The downloader maintains a manifest to track installed mods and automatically removes mods that are no longer in your list.

| Variable                      | Description                                                                                             | Default    |
|-------------------------------|---------------------------------------------------------------------------------------------------------|------------|
| `CURSEFORGE_MOD_IDS`          | Comma-separated list of CurseForge mod project IDs (e.g., `12345,67890`)                                | `(Empty)`  |
| `HYTALE_MOD_DIR`              | Directory where mods are downloaded                                                                     | `./mods` |

### Usage Example

```yaml
environment:
  CURSEFORGE_MOD_IDS: "12345,67890,11111"
```

### How It Works

1. On startup, the downloader fetches mod info from cflookup.com
2. Downloads the latest version from forgecdn.net if not already present
3. Removes mods that were previously downloaded but are no longer in `CURSEFORGE_MOD_IDS`
4. Maintains a manifest file (`.curseforge_manifest.json`) in the mods directory

### Finding Mod IDs

The mod ID can be found in the CurseForge URL. For example:
- URL: `https://www.curseforge.com/hytale/mods/example-mod/12345`
- Mod ID: `12345`

---

## 🎮 Hytale Server Options

Options are listed in the same order as they appear in `java -jar HytaleServer.jar --help`.

| Variable                          | Description                                                                                                                                                             | Default     |
|-----------------------------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------|-------------|
| `HYTALE_CACHE`                    | Enables the Ahead-Of-Time cache                                                                                                                                         | `FALSE`     |
| `HYTALE_CACHE_DIR`                | Sets the location of the Ahead-Of-Time cache file                                                                                                                       | `./Server/HytaleServer.aot` |
| `HYTALE_ACCEPT_EARLY_PLUGINS`     | Allow loading early or experimental plugins (unsupported and may cause stability issues)                                                                                | `FALSE`     |
| `HYTALE_ALLOW_OP`                 | Automatically grant operator permissions                                                                                                                                | `FALSE`     |
| `HYTALE_AUTH_MODE`                | Authentication mode: `authenticated`, `offline`, or `insecure`. `authenticated` is the built-in default.                                                                | `(Empty)`   |
| `HYTALE_BACKUP`                   | Create a backup on server startup (requires `HYTALE_BACKUP_DIR` to be set)                                                                                              | `FALSE`     |
| `HYTALE_BACKUP_DIR`               | Directory where backups are stored. Setting this enables the `/backup` command in-game. The default `./backups` adds a `backups` directory to your mounted data folder. | `./backups` |
| `HYTALE_BACKUP_FREQUENCY`         | Frequency of scheduled backups in minutes                                                                                                                               | `(Empty)`   |
| `HYTALE_BACKUP_MAX_COUNT`         | Maximum number of backups to keep                                                                                                                                       | `(Empty)`   |
| `HYTALE_BARE`                     | Runs server bare (without loading worlds, binding to ports or creating directories)                                                                                     | `FALSE`     |
| `HYTALE_BOOT_COMMAND`             | Command to run on boot (multiple commands execute synchronously in order)                                                                                               | `(Empty)`   |
| `HYTALE_CLIENT_PID`               | Client process ID (for integrated server scenarios)                                                                                                                     | `(Empty)`   |
| `HYTALE_DISABLE_ASSET_COMPARE`    | Disable asset comparison checks                                                                                                                                         | `FALSE`     |
| `HYTALE_DISABLE_CPB_BUILD`        | Disable building of compact prefab buffers                                                                                                                              | `FALSE`     |
| `HYTALE_DISABLE_FILE_WATCHER`     | Disable file watcher                                                                                                                                                    | `FALSE`     |
| `HYTALE_DISABLE_SENTRY`           | Disable Sentry error reporting                                                                                                                                          | `FALSE`     |
| `HYTALE_EARLY_PLUGINS`            | Additional early plugin directories to load from (Path)                                                                                                                 | `(Empty)`   |
| `HYTALE_EVENT_DEBUG`              | Enable event debugging                                                                                                                                                  | `FALSE`     |
| `HYTALE_FORCE_NETWORK_FLUSH`      | Force network flush behavior                                                                                                                                            | `true`      |
| `HYTALE_GENERATE_SCHEMA`          | Generate schema, save to assets directory and exit                                                                                                                      | `FALSE`     |
| `HYTALE_IDENTITY_TOKEN`           | Identity token (JWT)                                                                                                                                                    | `(Empty)`   |
| `HYTALE_LOG`                      | Sets logger level (KeyValueHolder format)                                                                                                                               | `(Empty)`   |
| `HYTALE_MIGRATE_WORLDS`           | Worlds to migrate (comma-separated)                                                                                                                                     | `(Empty)`   |
| `HYTALE_MIGRATIONS`               | The migrations to run (JSON object)                                                                                                                                     | `(Empty)`   |
| `HYTALE_MODS`                     | Additional mods directories (Path)                                                                                                                                      | `(Empty)`   |
| `HYTALE_OWNER_NAME`               | Server owner name                                                                                                                                                       | `(Empty)`   |
| `HYTALE_OWNER_UUID`               | Server owner UUID                                                                                                                                                       | `(Empty)`   |
| `HYTALE_PREFAB_CACHE`             | Prefab cache directory for immutable assets                                                                                                                             | `(Empty)`   |
| `HYTALE_SESSION_TOKEN`            | Session token for Session Service API                                                                                                                                   | `(Empty)`   |
| `HYTALE_SHUTDOWN_AFTER_VALIDATE`  | Automatically shutdown after asset and/or prefab validation                                                                                                             | `FALSE`     |
| `HYTALE_SINGLEPLAYER`             | Run server in singleplayer mode                                                                                                                                         | `FALSE`     |
| `HYTALE_TRANSPORT`                | Transport type: `QUIC` or other supported types. `QUIC` is the built-in default.                                                                                        | `(Empty)`   |
| `HYTALE_UNIVERSE`                 | Universe directory path                                                                                                                                                 | `(Empty)`   |
| `HYTALE_VALIDATE_ASSETS`          | Exit with error if any assets are invalid                                                                                                                               | `FALSE`     |
| `HYTALE_VALIDATE_PREFABS`         | Validation option for prefabs (exits with error if invalid)                                                                                                             | `(Empty)`   |
| `HYTALE_VALIDATE_WORLD_GEN`       | Exit with error if default world gen is invalid                                                                                                                         | `FALSE`     |
| `HYTALE_VERSION`                  | Print version information and exit                                                                                                                                      | `FALSE`     |
| `HYTALE_WORLD_GEN`                | World generation directory path                                                                                                                                         | `(Empty)`   |

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