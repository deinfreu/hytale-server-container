---
layout: default
title: "Debug"
parent: "📥 Installation"
nav_order: 4
---

## 🐞 Debug Mode

If you are experiencing issues with your installation, I have included an automated diagnostic script that audits your **network configurations** and **security settings** during the container startup.

### 🛠️ How to Enable Diagnostics

- Make sure you don't have the slim image. Simply remove '-slim' from the docker image name.
- Enable the enviroment variable DEBUG and set it to "TRUE".