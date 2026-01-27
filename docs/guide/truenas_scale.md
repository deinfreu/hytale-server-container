---
layout: default
title: "Truenas Scale"
parent: "📓 Guide"
nav_order: 1
---

Take a look at the [example](https://github.com/deinfreu/hytale-server-container/tree/main/examples/truenas_scale) files in the GitHub repository for setting up Hytale Server Container on TrueNAS Scale.

To create a custom app in TrueNAS Scale, follow these steps:

1. Go to the TrueNAS Scale web interface and navigate to the "Apps" section.
2. Click on "Discover Apps".
3. Click on the three dots next to the button "Custom App" in the top right corner.
4. Select "Install via YAML".
5. Paste the contents of one of the example files from the [examples](https://github.com/deinfreu/hytale-server-container/tree/main/examples/truenas_scale) directory in the GitHub repository.
6. Modify the configuration as needed, such as setting environment variables, volumes, and ports. Don't forget to add a name for your app.
7. Click "Save" to create the custom app.

To make yourself an operator in the Hytale server, use the following command inside the container shell:

```bash
echo "op add USERNAME" > /tmp/hytale-console.in
```

---

**Go to the [Support page](./support.md) if you need help!