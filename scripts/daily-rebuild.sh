#!/bin/bash
set -e

REGION="ap-northeast-1"
CLUSTER_NAME="devops-eks"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"


echo "=== Daily Rebuild Script ==="
read -rp "確定執行完整重建? (y/N) " confirm
[[ "$confirm" =~ ^[yY]$ ]] || { echo "取消"; exit 0; }

# Step 1: Terraform
echo ""
echo "=== Step 1: terraform apply ==="
cd "${PROJECT_DIR}/terraform/eks"
terraform init
terraform apply -auto-approve
cd "$PROJECT_DIR"

# Step 2: 等待 nodes ready
echo ""
echo "=== Step 2: 等待 nodes ready ==="
kubectl wait --for=condition=Ready nodes --all --timeout=15m

# Step 3: ALB Controller
echo ""
echo "=== Step 3: ALB Controller ==="
kubectl apply -f "${PROJECT_DIR}/k8s/setup/ServiceAccount.yaml"
helm upgrade --install aws-load-balancer-controller \
  eks/aws-load-balancer-controller \
  -n kube-system \
  -f "${PROJECT_DIR}/helm/aws-load-balancer-controller/values.yaml"

# Step 4: Monitoring
echo ""
echo "=== Step 4: Monitoring stack ==="
bash "${SCRIPT_DIR}/setup-monitoring.local.sh"

# Step 5: 更新日期 + git push
echo ""
echo "=== Step 5: 更新 index.html 日期 + git push ==="
DATE="$(date +%-m/%-d)"
# 替換以數字開頭的 <p>（日期行），保留第一個 <p>（Deployed...）
sed -i "s|<p>[0-9][^<]*</p>|<p>${DATE}</p>|" "${PROJECT_DIR}/app/index.html"
echo "index.html 日期更新為: $DATE"
cd "$PROJECT_DIR"
git add app/index.html
if git diff --cached --quiet; then
  echo "（日期未變更，使用 empty commit 觸發 CI/CD）"
  git commit --allow-empty -m "chore: trigger deploy on ${DATE}"
else
  git commit -m "chore: update date to ${DATE}"
fi
git push

# Step 6: 等待 ALB active
echo ""
echo "=== Step 6: 等待 ALB ready... ==="
while true; do
  STATE=$(aws elbv2 describe-load-balancers \
    --region "$REGION" \
    --query 'LoadBalancers[0].State.Code' \
    --output text 2>/dev/null)
  DNS=$(aws elbv2 describe-load-balancers \
    --region "$REGION" \
    --query 'LoadBalancers[0].DNSName' \
    --output text 2>/dev/null)

  printf "ALB State: %-15s DNS: %s\n" "${STATE:-waiting...}" "${DNS:-N/A}"

  if [[ "$STATE" == "active" ]]; then
    break
  fi
  sleep 15
done

echo ""
echo "=== Step 7: 等待應用程式就緒 (HTTP 200)... ==="
while true; do
  HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "http://$DNS")
  printf "HTTP Status: %s\n" "$HTTP_CODE"
  if [[ "$HTTP_CODE" == "200" ]]; then
    break
  fi
  sleep 10
done

echo ""
echo "=== Done! ==="
echo "URL: http://$DNS"
echo ""
echo "--- curl 結果 ---"
curl -s "http://$DNS"

echo ""
echo "開啟瀏覽器..."
cmd.exe /c "start http://$DNS" 2>/dev/null || echo "請手動開啟: http://$DNS"
