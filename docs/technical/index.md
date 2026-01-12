---
layout: default
title: "⚙️ Technical Info"
has_children: true
nav_order: 3
---

## 🐞 Debug Mode

If you are experiencing issues with your installation, I have included an automated diagnostic script that audits your **network configurations** and **security settings** during the container startup.

## 🛠️ How to Enable Diagnostics

- Make sure you don't have the slim image. Simply remove '-slim' from the docker image name.
- Enable the enviroment variable DEBUG and set it to "TRUE".

# Support

* Check our [FAQ](https://deinfreu.github.io/hytale-server-container/faq) for frequently asked questions