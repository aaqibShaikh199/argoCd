# Argo CD Demo

Static HTML/CSS site served by NGINX and deployed to Kubernetes with Argo CD.

Pushes to `main` that change the site run `.github/workflows/ci.yml`. It builds the image, pushes it to GHCR, and writes the new tag into `deployment.yaml` for Argo CD to sync. Make the GHCR package public so the cluster can pull it.

To change the background color, edit line 11 of `style.css` (`background: red;`), replace `red` with another color, and push to `main`.

`./install-argocd.sh` installs a local non-HA Argo CD.
