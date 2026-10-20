# 🚀 Argo CD GitOps Learning Project

A simple containerized static website built using HTML and CSS, served by NGINX. This project is created to learn **GitOps, Argo CD, Kubernetes deployments, and continuous delivery**.

## 📌 Project Overview

- **Frontend:** HTML and CSS
- **Web Server:** NGINX
- **Containerization:** Docker
- **Continuous Delivery:** Argo CD
- **Orchestration:** Kubernetes

## 🎨 Change Application Color

You can change the application's background color by editing just **one line** in `style.css`.

### Step 1: Open `style.css`

Find the following line inside the `body` CSS selector:

```css
background: #2563eb;
```

### Step 2: Choose Your Color

Replace the existing color code with one of the following:

| Version | Color Code |
|---|---|
| 🔵 Blue | `#2563eb` |
| 🟢 Green | `#16a34a` |
| 🔴 Red | `#dc2626` |
| ⚫ Black | `#171717` |

For example, to change the application to Green:

```css
body {
  margin: 0;
  min-height: 100vh;
  font-family: Arial, sans-serif;
  background: #16a34a;
  color: white;
}
```

**Note:** Only change the `background` color value. Keep the rest of the CSS unchanged.

## 🔄 Deploy Changes Using Git and Argo CD

After changing the color, commit and push your changes to GitHub.

```bash
git add style.css
git commit -m "Update application background color"
git push origin main
```

If Argo CD is configured for automatic synchronization, it will reconcile the Kubernetes resources when the tracked Git configuration changes.

### Important: Docker Image Updates

If `style.css` is copied into the Docker image during the build, changing the file in Git alone will not update the running website. You must:

1. Build a new Docker image.
2. Push the image to your container registry.
3. Update the image tag in your Kubernetes manifests.
4. Let Argo CD synchronize the updated manifests.

Alternatively, if the application files are mounted into the container through a ConfigMap or volume, the update process depends on that configuration.

## 🧪 Learning Goals

- Understand GitOps and Argo CD synchronization.
- Practice Git commits and GitHub pushes.
- Learn how application changes reach Kubernetes.
- Experiment with different application versions and colors.
- Understand the difference between updating source code and deploying a new container image.

## 👨‍💻 Author

**Shaikh Aaqib**

*Learn • Build • Deploy • Repeat* 🚀
