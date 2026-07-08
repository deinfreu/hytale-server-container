---
layout: default
title: "Development"
parent: "Documentation"
nav_order: 3
---

# Local Development

This page covers all approaches for running the documentation site and building the server container locally.

---

## Building the Server Container

Build the Hytale server Docker image yourself on Linux.

### Step 1: Clone the Repository

Copy (clone) this repository and navigate into it:

```bash
git clone https://github.com/deinfreu/hytale-server-container.git
cd hytale-server-container
```

### Step 2: Create docker-compose.yml

Create a file named `docker-compose.yml` inside this folder.

```bash
nano docker-compose.yml
```

Add the following content to the file:

```yaml
services:
  hytale:
    build:
      context: .
      dockerfile: Dockerfile.ubuntu
    container_name: hytale-server
    environment:
      SERVER_IP: "0.0.0.0"
      SERVER_PORT: "5520"
    restart: unless-stopped
    ports:
      - "5520:5520/udp"
    volumes:
      - ./data:/home/container
      - /etc/machine-id:/etc/machine-id:ro
    tty: true
    stdin_open: true
```

### Step 3: Save the File

| Operating System      | Step 1: Write Out | Step 2: Confirm Filename | Step 3: Exit Editor |
| --------------------- | ----------------- | ------------------------ | ------------------- |
| Linux / Windows (WSL) | Press Ctrl + O    | Press Enter              | Press Ctrl + X      |
| macOS                 | Press Control + O | Press Return             | Press Control + X   |

{: .important }
> This `data` folder will be created on your host OS in the same directory as your `docker-compose.yml` file. Your game files, world data, and configurations are stored here and persist even if you stop or delete the Docker container. If you prefer to use volume mounts instead of bind mounts, see the [volume mount example](https://github.com/deinfreu/hytale-server-container/tree/main/examples/docker-compose/volume_mount).

### Step 4: Build and Run

Build the image and start the server:

```bash
docker compose up --build
```

---

## Running the Documentation Site Locally

Run the Jekyll docs site on your machine using Ruby and Bundler.

### Step 1: Install Ruby

Ensure Ruby version **3.0 or higher** is installed:

```bash
ruby --version
```

If Ruby is not installed, install it via your package manager. For example on Ubuntu/Debian (WSL2):

```bash
sudo apt update && sudo apt install ruby-full -y
```

### Step 2: Add Gems to Your PATH

Ruby installs gems in a user directory by default, which may not be in your `PATH`. Add it to your shell profile so bundler is always available.

Add this line to the **end** of your `~/.bashrc` file (WSL2) or `~/.zshrc`:

```bash
echo 'export PATH="$HOME/.local/share/gem/ruby/3.3.0/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

> **Note:** If your Ruby version differs (e.g., 3.1, 3.2), adjust the path accordingly. You can find your gem home with `gem env | grep -i "USER INSTALLATION DIR"`.

### Step 3: Install Bundler

Install the Bundler gem (used to manage Jekyll dependencies):

```bash
gem install bundler
bundle --version
```

Verify it outputs a version number (e.g., `Bundler version 2.x.x`). If you still see "command not found", confirm your `PATH` is set correctly by running:

```bash
echo $PATH
```

### Step 4: Install Dependencies

Navigate to the `docs` folder and install all required gems:

```bash
cd docs
bundle install
```

The gems will be installed into `vendor/bundle` within the `docs` directory.

### Step 5: Start the Jekyll Server

Run the local development server with live reload:

```bash
bundle exec jekyll serve --livereload
```

The site will be available at **http://localhost:4000**.

> Press `Ctrl + C` in the terminal to stop the server.
