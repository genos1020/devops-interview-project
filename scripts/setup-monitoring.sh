#!/bin/bash
set -e

NAMESPACE="monitoring"

echo "=== Step 1: 建立 monitoring namespace ==="
kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -

echo "=== Step 2: 建立 Telegram Secret ==="
if [ -z "$TELEGRAM_TOKEN" ] || [ -z "$TELEGRAM_CHAT_ID" ]; then
  echo "請輸入 Telegram Bot Token:"
  read -r TELEGRAM_TOKEN
  echo "請輸入 Telegram Chat ID:"
  read -r TELEGRAM_CHAT_ID
fi

if [ -z "$GRAFANA_PASSWORD" ]; then
  echo "請輸入 Grafana Admin 密碼:"
  read -r GRAFANA_PASSWORD
fi

kubectl create secret generic alertmanager-telegram \
  --from-literal=TELEGRAM_TOKEN="$TELEGRAM_TOKEN" \
  --from-literal=TELEGRAM_CHAT_ID="$TELEGRAM_CHAT_ID" \
  -n "$NAMESPACE" \
  --dry-run=client -o yaml | kubectl apply -f -

echo "=== Step 3: 安裝 kube-prometheus-stack ==="
helm upgrade --install prometheus-operator \
  prometheus-community/kube-prometheus-stack \
  --namespace "$NAMESPACE" \
  --set grafana.adminPassword="$GRAFANA_PASSWORD" \
  -f helm/kube-prometheus-stack/values.yaml

echo "=== Step 4: 套用 alertmanager config ==="
kubectl apply -f k8s/setup/alertmanager-config.yaml

echo "=== Step 5: 套用 ServiceMonitor ==="
kubectl apply -f k8s/setup/servicemonitor.yaml

echo ""
echo "完成！"
