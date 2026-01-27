---
layout: default
title: "2. Container Installation"
parent: "📥 Installation"
nav_order: 2
---

## 📥 Container installation

### Method A: Docker CLI

Run this command in your terminal to start the server immediately:

```bash
docker run \
  --name hytale-server \
  -e SERVER_IP="0.0.0.0" \
  -e SERVER_PORT="5520" \
  -e PROD="FALSE" \
  -e DEBUG="FALSE" \
  -e TZ="Europe/Amsterdam" \
  -p 5520:5520/udp \
  -v "hytale-server:/home/container" \
  -v "/etc/machine-id:/etc/machine-id:ro" \
  --restart unless-stopped \
  deinfreu/hytale-server:experimental
```

---

### Method B: Docker compose

1.  **Prepare a Directory:** Create a dedicated folder inside your home directory to keep your project organized:
    ```bash
    mkdir ~/hytale-server && cd ~/hytale-server
    ```
2.  **Configuration:** Create a file named `docker-compose.yml` inside this new folder.

    ```bash
    nano docker-compose.yml
    ```

    add this docker-compose.yml information to the file:

    ```yaml
    services:
      hytale:
        image: deinfreu/hytale-server:experimental
        container_name: hytale-server
        environment:
          SERVER_IP: "0.0.0.0"
          SERVER_PORT: "5520"
          PROD: "FALSE"
          DEBUG: "FALSE"
          TZ: "Europe/Amsterdam"
        restart: unless-stopped
        ports:
          - "5520:5520/udp"
        volumes:
          - ./data:/home/container
          - /etc/machine-id:/etc/machine-id:ro
    ```

3.  Now get out of the nano text editor and save the file:

    | Operating System      | Step 1: Write Out | Step 2: Confirm Filename | Step 3: Exit Editor |
    | --------------------- | ----------------- | ------------------------ | ------------------- |
    | Linux / Windows (WSL) | Press Ctrl + O    | Press Enter              | Press Ctrl + X      |
    | macOS                 | Press Control + O | Press Return             | Press Control + X   |

    > **Automatic folder creation:** When you start the container, a `data` folder will be created automatically next to your `docker-compose.yml`.

    > **[IMPORTANT]**
    > Your game files, world data, and configurations will be stored in this `data` folder. Because this folder is mapped to the container, your progress is saved even if you stop or delete the Docker container.

4.  Run the docker compose file!

    ```bash
    docker compose up
    ```

    > Tip: do not use -d. We need to use the terminal to authenticate the server.

---

### Windows Users (Docker Desktop with WSL)

If you're running Docker Desktop on Windows with WSL, the default `/etc/machine-id` volume binding won't work. Follow these steps instead:

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

---

Go to the [Next page](./running_server.md)!