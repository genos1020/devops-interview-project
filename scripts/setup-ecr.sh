#!/bin/bash
set -e

REPO_NAME="devops-interview-app"
REGION="ap-northeast-1"
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
ECR_URL="${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "=== Step 1: 建立 ECR Repository ==="
aws ecr create-repository \
  --repository-name "$REPO_NAME" \
  --region "$REGION" 2>/dev/null || echo "Repository 已存在，略過"

echo "=== Step 2: 登入 ECR ==="
aws ecr get-login-password --region "$REGION" | \
  docker login --username AWS --password-stdin "$ECR_URL"

echo "=== Step 3: Build + Tag + Push ==="
docker build -t "$REPO_NAME" -f "${SCRIPT_DIR}/../docker/Dockerfile" "${SCRIPT_DIR}/.."

docker tag "${REPO_NAME}:latest" "${ECR_URL}/${REPO_NAME}:latest"

docker push "${ECR_URL}/${REPO_NAME}:latest"

echo "=== Step 4: 建立 EKS imagePullSecret ==="
kubectl create secret docker-registry ecr-secret \
  --docker-server="$ECR_URL" \
  --docker-username=AWS \
  --docker-password="$(aws ecr get-login-password --region "$REGION")" \
  --dry-run=client -o yaml | kubectl apply -f -

echo ""
echo "完成！ECR image URL："
echo "  ${ECR_URL}/${REPO_NAME}:latest"
