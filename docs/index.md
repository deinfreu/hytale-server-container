---
layout: default
title: Home
nav_order: 1
---

# Hytale Docker Server
This project provides an optimized Alpine-based Docker image for Hytale.

## Installation
The fastest way to get started is with Docker Compose:

```yaml
services:
  hytale:
    image: deinfreu/hytale-server:experimental
    ports:
      - "23000:23000/udp"
    restart: always
```

---

### 3. `/docs/configuration.md`
This file creates the sidebar link.

```markdown
---
layout: default
title: Configuration
nav_order: 2
---

# Configuration

| Variable | Default | Description |
| :--- | :--- | :--- |
| `MEMORY` | `2G` | Max RAM for the JVM |
| `PORT` | `23000` | Server listen port |

## Example
`docker run -e MEMORY=4G deinfreu/hytale-server`