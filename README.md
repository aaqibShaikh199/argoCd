# Argo CD Demo

Static HTML/CSS site served by NGINX and deployed to Kubernetes with Argo CD.

Pushes to `main` that change the site run `.github/workflows/ci.yml`. It builds the image, pushes it to ECR (`aaqib-argocd-learning`), writes the new tag into `deployment.yaml`, and rolls it out on the EKS cluster `aaqib-argo-cd-learning`. Store the deploy role ARN in the `AWS_ROLE_ARN` GitHub secret.

To change the background color, edit line 11 of `style.css` (`background: red;`), replace `red` with another color, and push to `main`.

`./install-argocd.sh` installs a local non-HA Argo CD.
