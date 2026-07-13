---
layout: default
title: Home
nav_order: 1
permalink: /
description: "Official documentation for the Hytale Server Container — a lightweight, secure Docker image for self-hosting Hytale game servers on x86_64 and ARM64."
---

# Hytale server container
{: .fs-9 }

deinfreu/hytale-server-container

A lightweight, plug & play Docker container for hosting Hytale servers. With a tiny 61.7MB footprint, ARM64 support, secure non-root execution, and in-game updates.
{: .fs-6 .fw-400 }

[Getting started](/installation/requirements.md){: .btn .btn-primary .fs-5 .mb-4 .mb-md-0 .mr-2 }
[View it on GitHub](https://github.com/deinfreu/hytale-server-container){: .btn .fs-5 .mb-4 .mb-md-0 }

---

<video 
  width="100%" autoplay loop muted playsinline poster="./assets/images/terminal.jpg">
  <source src="./assets/videos/terminal.mp4" type="video/mp4">
  Your browser does not support the video tag.
</video>

## Hytale Server Hosting, Made Simple

I created this project to help everyone get started with building their own Hytale server to play on with friends. When I was younger, I used to set up Minecraft servers for my friends. I spent what felt like ages researching the most performant ways to run a server on low-spec hardware, just to squeeze every bit of efficiency out of the machine. While it resulted in great times playing together, in hindsight, I should have focused less on the technical setup and more on just creating and enjoying the game with friends.

Because of that experience, I designed this Hytale server Docker container with a few key architectural goals in mind. And I will keep improving them as we go!

Plug-and-play simplicity: I firmly believe that code found on the internet should be incredibly easy to run. There is nothing worse than finding the perfect solution to your problem, only to realize it doesn't work when you try it out. Running this Docker container and setting up a world for your friends should be effortless.

Optimized out-of-the-box: You shouldn't have to spend hours researching online how to get the best performance out of a Hytale server. The most optimal performance flags are already enabled by default!

For now, enjoy the smooth sailing and have fun playing the game! If you have any improvements in mind, feel free to open a GitHub issue.

## Key Features

* **Lightweight & Efficient:** Optimized images starting at just **61.7MB**, ensuring fast pulls and minimal resource consumption.
* **Multi-Arch Support:** Full native support for both `x86_64` and `ARM64` architectures.
* **Smart CLI:** Includes the `hytale-downloader` tool, allowing you to manage server binaries and check for updates directly from your terminal.
* **Secure by Design:** Engineered for secure, non-root execution by default.
* **Diagnostic Suite:** Built-in debug mode to automatically audit your network and security settings.
* **Seamless Updates:** Integrated tools designed for effortless, in-game server updates.
* **Community-Driven:** Actively maintained by a community of 10+ contributors, prioritizing stability and performance.

---

## Getting Started

Ready to host your world? Ensure you have the correct hardware and a valid Hytale license before proceeding:

1.  **[Requirements](./installation/requirements.md):** Prerequisites.
2.  **[Container Installation](./installation/container_installation.md):** Deploy your first server using CLI or Compose.
3.  **[Running the server](./installation/running_server.md):** Explanation on how to run the setup and run the Hytale server.
4.  **[Support](./installation/support.md):** Is your installation not working?
5.  **[Optimizations](./optimizations.md):** Want to go fast? Read here about all the optimizations.

---

## Build From Source

Want to build the Docker image yourself or run the documentation site locally? See our [Development guide](./documentation/development.md) for step-by-step instructions on building images and setting up your local environment.

---

## Need Help?

If you run into trouble, we have resources available:

* **[Frequently Asked Questions](./faq.md):** Common fixes for connection and time-zone issues.
* **[GitHub Issues](https://github.com/deinfreu/hytale-server-container/issues):** Report bugs or request new features.
* **[Discussions](https://discord.gg/M8yrdnHb32):** Connect with other Hytale server owners.

---

> **Disclaimer:** This project is not affiliated with HYPIXEL STUDIOS CANADA INC. A valid Hytale license is required to download the server binaries.