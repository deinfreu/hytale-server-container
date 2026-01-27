---
layout: default
title: "2. Container Installation"
parent: "📥 Installation"
nav_order: 2
---

## Container installation

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
  -it \
  deinfreu/hytale-server:latest
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
        image: deinfreu/hytale-server:latest
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
        tty: true
        stdin_open: true
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

Running a special OS like TrueNAS Scale, Unraid or Windows WSL2? Check out the [Guide section](../guide/index.md) for specific instructions!

---

Go to the [Next page](./running_server.md)!