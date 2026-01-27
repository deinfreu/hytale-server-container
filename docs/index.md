---
layout: default
title: 🏠 Home
nav_order: 1
description: "Hytale server container Documentation Home"
---

# Hytale Docker Server
{: .fs-9 }

A high-performance Docker container for hosting Hytale servers. Features automated binary management, cross-platform support, and built-in diagnostic tools.
{: .fs-6 .fw-300 }

[Getting started](/installation/requirements.md){: .btn .btn-primary .fs-5 .mb-4 .mb-md-0 .mr-2 }
[View it on GitHub](https://github.com/deinfreu/hytale-server-container){: .btn .fs-5 .mb-4 .mb-md-0 }

---

## Key Features

* **Fast server startup:** Startup your server in 7 seconds with `CACHE=TRUE`
* **Easy Deployment:** Go to the [installation](https://deinfreu.github.io/hytale-server-container/installation/) pages to get started
* **Smart CLI:** Includes the `hytale-downloader` tool to manage server binaries and check for updates automatically. You can just use "hytale-downloader" in the terminal to access it.
* **Multi-Arch Support:** Optimized for `x86_64` (`ARM64` coming soon [more info](https://x.com/slikey/status/2010869532454510999)).
* **Diagnostic Suite:** Built-in debug mode to audit your network and security settings automatically.
* **Slim Images:** Optimized, lightweight image variants for production environments.

---

## Getting Started

Ready to host your world? Ensure you have the correct hardware and a valid Hytale license before proceeding:

1.  **[Requirements](./installation/requirements.md):** Prerequisites.
2.  **[Container Installation](./installation/container_installation.md):** Deploy your first server using CLI or Compose.
3.  **[Running the server](./installation/running_server.md):** Explenation how to run the setup and run the hytale server.
4.  **[Support](./installation/support.md.md):** Is your installation not working?
5.  **[Optimizations](./optimizations.md):** Want to go fast? Read here about all the optimizations.

---

## Need Help?

If you run into trouble, we have resources available:

* **[Frequently Asked Questions](./faq.md):** Common fixes for connection and time-zone issues.
* **[GitHub Issues](https://github.com/deinfreu/hytale-server-container/issues):** Report bugs or request new features.
* **[Discussions](https://discord.gg/M8yrdnHb32):** Connect with other Hytale server owners.

---

## About the project

Hytale Server Container &copy; 2025-{{ "now" | date: "%Y" }} by [Deinfreu](https://github.com/deinfreu) and the [Hytale Server Container contributors](https://github.com/deinfreu/hytale-server-container/graphs/contributors).

### License

Hytale Server Container is distributed under the [APACHE-2.0](https://github.com/deinfreu/hytale-server-container/blob/main/LICENSE) license.

### Contributing

When contributing to this repository, please first discuss the change you wish to make via issue,
email, or any other method with the owners of this repository before making a change.

#### Thank you to the contributors of Just the Docs!

<ul class="list-style-none">
{% for contributor in site.github.contributors %}
  <li class="d-inline-block mr-1">
     <a href="{{ contributor.html_url }}"><img src="{{ contributor.avatar_url }}" width="32" height="32" alt="{{ contributor.login }}"></a>
  </li>
{% endfor %}
</ul>

----

> **Disclaimer:** This project is not affiliated with HYPIXEL STUDIOS CANADA INC. A valid Hytale license is required to download the server binaries.
