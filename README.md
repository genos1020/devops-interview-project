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