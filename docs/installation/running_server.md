---
layout: default
title: "4. Running the server"
parent: "📥 Installation"
nav_order: 4
---

## Running the container
We are now going to start the server!

1. **Authenticate the `hytale-downloader` CLI tool**

    Follow the instructions on the screen and log in to your Hytale account in the browser. The script automatically downloads the server files if you do not already have them installed.

    > **[TIP]**: If you run your Docker container on an external server, use an SSH terminal in your desktop environment to connect to the Docker container to proceed with the authentication flows.

2. **Downloading and extracting the server binary**

    Please be patient; the server is downloading and extracting the necessary files.

    > **[INFO]**: This step takes approximately 2 minutes on a Ryzen 5950X with a 1 Gbps asymmetrical connection.

3. **Attach to the Java process**

    On your Docker host machine, type the following in the terminal:

    ```bash
    docker attach hytale-server
    ```

    > **[INFO]**
    > You should see a ">" sign. This means you are successfully connected to the Java process.

4. **Authenticate the server** 

    This prevents the need to log in again every time the container restarts.

    ```bash
    /auth persistence Encrypted
    ```
    
    > **[INFO]** "Encrypted" with a capital.

    Run the following command to authorize the server and follow the steps:

    ```bash
    /auth login device
    ```

5. **Done!**

**Go to the [Debug page](./debug.md)** **or go to the [Support page](./support.md)!**