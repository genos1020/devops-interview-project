# DevOps Interview Project

## Architecture
- Kubernetes (k3d locally, EKS later)
- Helm for k8s deployment
- Ingress for external access

## Local Setup
1. k3d cluster create
2. helm install my-nginx ./helm/nginx-chart
3. curl devops.localhost

## Roadmap
- [ ] CI/CD with GitHub Actions
- [ ] Terraform provision EKS
- [ ] GitOps


## CI/CD Pipeline Architecture
Developer
   |
   | git push
   v
GitHub Repository
   |
   | GitHub Actions (CI/CD)
   |
   +--> CI Stage
   |      - Checkout source code
   |      - Docker build image
   |      - Tag image with Git SHA
   |      - Push image to Docker Hub
   |
   +--> CD Stage
          - Load KUBECONFIG from GitHub Secrets
          - Helm upgrade --install
          - Update image.tag to new version
          - Kubernetes Deployment rolling update
   |
   v
Kubernetes Cluster
   |
   | Service / Ingress
   v
User Request (Browser / curl)

