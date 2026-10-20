# Argo CD Demo

Static HTML/CSS site served by NGINX and deployed to Kubernetes with Argo CD.

```bash
docker build -t <dockerhub-user>/argocd-demo:v1.0.0 .
docker push <dockerhub-user>/argocd-demo:v1.0.0
```

Put that image in `deployment.yaml`, then apply `deployment.yaml` and `service.yaml` (or let Argo CD sync them).

To change the background color, edit line 11 of `style.css` (`background: red;`) and replace `red` with another color, then rebuild and push a new image tag.

`./install-argocd.sh` installs a local non-HA Argo CD.
