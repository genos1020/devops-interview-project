#!/bin/bash
set -e

RELEASE_NAME="my-nginx"
NAMESPACE="default"
DEPLOY_NAME="my-nginx-nginx-chart"

echo "=== Step 1: Helm Upgrade ==="
helm upgrade "$RELEASE_NAME" ./helm/nginx-chart --namespace "$NAMESPACE"

echo ""
echo "=== Step 2: 查看 Helm 歷史版本 ==="
helm history "$RELEASE_NAME"

echo ""
echo "=== Step 3: Rollback 到上一個版本 ==="
PREV_REVISION=$(helm history "$RELEASE_NAME" --output json | \
  python3 -c "import sys,json; h=json.load(sys.stdin); print(sorted(h, key=lambda x: x['revision'])[-2]['revision'])")

echo "Rollback 到 revision: $PREV_REVISION"
helm rollback "$RELEASE_NAME" "$PREV_REVISION"

echo ""
echo "=== Step 4: 觸發告警 - scale replicas 到 0 ==="
kubectl scale deploy "$DEPLOY_NAME" --replicas=0 -n "$NAMESPACE"
echo "已縮到 0，等待 Telegram 收到告警..."
echo "（等告警收到後按 Enter 恢復）"
read -r

echo ""
echo "=== Step 5: 恢復 replicas ==="
kubectl scale deploy "$DEPLOY_NAME" --replicas=2 -n "$NAMESPACE"
kubectl rollout status deploy "$DEPLOY_NAME" -n "$NAMESPACE"

echo ""
echo "完成！"
