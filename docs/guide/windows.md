---
layout: default
title: "Windows WSL2"
parent: "📓 Guide"
nav_order: 3
---

## Windows (Docker Desktop with WSL2)

If you're running Docker Desktop on Windows with the "docker-desktop" Linux image, the default `/etc/machine-id` volume binding should work out of the box. However, if you're running Ubuntu in WSL2, you'll need to follow these steps to ensure persistent server authorization:

1. **Modify the volume binding** in your `docker-compose.yml`:

   Change this:

   ```yaml
   volumes:
     - ./data:/home/container
     - /etc/machine-id:/etc/machine-id:ro
   ```

   To this:

   ```yaml
   volumes:
     - ./data:/home/container
     - ./machine-id:/etc/machine-id:ro
   ```

2. **Generate a machine-id file** by opening PowerShell in the same directory as your `docker-compose.yml` and running:

   ```powershell
   [guid]::NewGuid().ToString("N") | Out-File -Encoding ascii -NoNewline .\machine-id
   ```

3. **Restart the server** and authenticate it. You'll be fine going forward.

> **Note:** This creates a local `machine-id` file that persists with your project, ensuring consistent authentication across container restarts.
