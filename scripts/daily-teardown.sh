#!/bin/bash
set -e

REGION="ap-northeast-1"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

echo "=== Daily Teardown Script ==="
read -rp "確定執行完整拆除? (y/N) " confirm
[[ "$confirm" =~ ^[yY]$ ]] || { echo "取消"; exit 0; }

# Step 1: 刪除所有 Ingress（觸發 ALB Controller 將 ALB 一併刪除）
echo ""
echo "=== Step 1: 刪除 Ingress ==="
kubectl delete ing --all -A || echo "（無 Ingress 可刪除）"

# Step 2: 等待 ALB 從 AWS 消失
echo ""
echo "=== Step 2: 等待 ALB 刪除... ==="
while true; do
  COUNT=$(aws elbv2 describe-load-balancers \
    --region "$REGION" \
    --query 'length(LoadBalancers)' \
    --output text 2>/dev/null)

  printf "ALB 數量: %s\n" "${COUNT:-0}"

  if [[ "$COUNT" == "0" || -z "$COUNT" ]]; then
    break
  fi
  sleep 15
done

# Step 3: terraform destroy
echo ""
echo "=== Step 3: terraform destroy ==="
cd "${PROJECT_DIR}/terraform/eks"
terraform destroy -auto-approve

echo ""
echo "=== Teardown 完成 ==="
