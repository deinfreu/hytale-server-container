# Local Development

This folder contains files for local Jekyll development and testing.

## Running Locally

From the `docs/dev/` directory:

```bash
docker compose up
```

The site will be available at http://localhost:4000/hytale-server-container/

## Files

- `docker-compose.yml` - Docker Compose configuration for Jekyll
- `Dockerfile` - Jekyll container build configuration
- `.dockerignore` - Files to exclude from Docker builds

**Note:** This folder is excluded from GitHub Pages deployment and git tracking.
