# 🚀 Argo CD GitOps Learning Project

A simple containerized static website built using HTML and CSS, served by NGINX. This project is created to learn GitOps, Argo CD, Docker, and Kubernetes deployments through practical hands-on experience.

## 📌 Project Overview

- **Frontend:** HTML and CSS
- **Web Server:** NGINX
- **Containerization:** Docker
- **Continuous Delivery:** Argo CD
- **Orchestration:** Kubernetes

## 🎯 Project Goal

The goal of this project is to understand how application changes can be managed through Git and deployed to Kubernetes using Argo CD.

You can experiment with different background colors, commit changes to GitHub, and practice application deployments.

## 🎨 Change Application Color

You can change the application's background color by editing just **one line** in `style.css`.

### Step 1: Open `style.css`

Find the `body` selector and locate the `background` property:

```css
body {
  margin: 0;
  min-height: 100vh;
  font-family: Arial, sans-serif;
  background: #2563eb;
  color: white;
}
```

### Step 2: Choose Your Color

Replace the existing background color code with any of these 10 colors.

| Version | Color | Color Code |
|---|---|---|
| 1 | 🔵 Blue | `#2563eb` |
| 2 | 🟢 Green | `#16a34a` |
| 3 | 🔴 Red | `#dc2626` |
| 4 | ⚫ Black | `#171717` |
| 5 | 🟣 Purple | `#9333ea` |
| 6 | 🟠 Orange | `#ea580c` |
| 7 | 🩷 Pink | `#db2777` |
| 8 | 🩵 Teal | `#0d9488` |
| 9 | 🟡 Gold | `#ca8a04` |
| 10 | 🌊 Indigo | `#4f46e5` |

**Example:** To change the background color to Green, update the CSS property:

```css
background: #16a34a;
```

Only change the color code. Keep the rest of the CSS unchanged.

### Step 3: Update the Version Label

If your HTML displays a version name and number, update them as needed.

For example:

```html
<h2>Version 2.0</h2>
<span>GREEN EDITION</span>
```

This step is optional if you only want to change the background color.

## 🔄 Deploy Changes Using Git and Argo CD

After changing the color, commit and push your changes to GitHub.

### Step 1: Add the Changes

```bash
git add style.css index.html
```

If you changed only `style.css`, you can use:

```bash
git add style.css
```

### Step 2: Commit the Changes

```bash
git commit -m "Update application background color"
```

### Step 3: Push to GitHub

```bash
git push origin main
```

### Step 4: Sync with Argo CD

If automatic synchronization is enabled and your Git change affects the resources Argo CD tracks, Argo CD will reconcile those changes automatically.

Otherwise, sync the application manually from the Argo CD UI or CLI.

## 🐳 Important: Docker Image Updates

If `index.html` and `style.css` are copied into the Docker image during the build, pushing the source code to GitHub alone will not update the running website.

Follow these steps:

1. Build a new Docker image containing the updated files.
2. Push the image to your container registry.
3. Update the image tag in your Kubernetes manifests.
4. Push the manifest changes to GitHub.
5. Let Argo CD synchronize the updated manifests.

If your website files are mounted through a ConfigMap or volume instead, follow the update process appropriate to that configuration.

## 🧪 Learning Goals

- Understand GitOps and the role of Argo CD.
- Practice Git commits and GitHub pushes.
- Learn how application changes reach Kubernetes.
- Experiment with 10 different background colors.
- Understand the difference between source-code changes and container-image updates.
- Practice deployment synchronization and revision history.

## 👨‍💻 Author

**Shaikh Aaqib**

*Learn • Build • Deploy • Repeat* 🚀
