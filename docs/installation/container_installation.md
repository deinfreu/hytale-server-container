---
layout: default
title: "Container installation"
parent: "📥 Installation"
nav_order: 3
---

## 📥 Container installation

1. **Install Docker:** Ensure Docker is installed and the service is running.
2. **Network Optimization:** For the best experience, ensure UDP/QUIC optimizations are applied to your host.
3. **Deploy the Container:** Choose one of the two methods below.

### Method A: Docker CLI
Run this command in your terminal to start the server immediately:

```bash
docker run -d \
  --name hytale-server \
  --restart unless-stopped \
  -e EULA="TRUE" \
  -e DEBUG="FALSE" \
  -p 5520:5520/udp \
  -v freudend-docker-hytale-server:/home/container \
  freudend/docker-hytale-server:latest
```

### Method B: Docker compose

1.  **Prepare a Directory:** Create a dedicated folder inside your home directory to keep your project organized:
    ```bash
    mkdir ~/hytale-server && cd ~/hytale-server
    ```
2.  **Configuration:** Create a file named `docker-compose.yml` inside this new folder.
    ``` bash
    nano docker-compose.yml
    ```
    add this docker-compose.yml information to the file:
    ``` yaml
    services:
    hytale-server:
        image: freudend/docker-hytale-server:latest
        container_name: hytale-server
        restart: unless-stopped
        environment:
        EULA: "TRUE"
        DEBUG: "FALSE"
        ports:
        - "5520:5520/udp"
        volumes:
        - ./data:/home/container
    ```

    Now get out of the nano text editor:

    | Operating System        | Step 1: Write Out | Step 2: Confirm Filename | Step 3: Exit Editor |
    |-------------------------|------------------|--------------------------|---------------------|
    | Linux / Windows (WSL)   | Press Ctrl + O   | Press Enter              | Press Ctrl + X      |
    | macOS                   | Press Control + O| Press Return             | Press Control + X   |


    > **Automatic folder creation:** When you start the container, a `data` folder will be created automatically next to your `docker-compose.yml`. 

    > **[IMPORTANT]**
    > Your game files, world data, and configurations will be stored in this `data` folder. Because this folder is mapped to the container, your progress is saved even if you stop or delete the Docker container.

4. **Run the docker compose file** 

    ```bash
    docker compose up
    ```
    > Tip: If you don't want to see the logs add "-d" at the end

5. **Check the status of your docker container**

    ```bash
    docker ps
    ```

That's all you need to know to start! 🎉