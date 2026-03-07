#!/bin/bash
set -e

ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
BUCKET_NAME="terraform-state-${ACCOUNT_ID}"
DYNAMODB_TABLE="terraform-lock"
REGION="ap-northeast-1"

echo "=== Step 1: 建立 S3 Bucket ==="
aws s3api create-bucket \
  --bucket "$BUCKET_NAME" \
  --region "$REGION" \
  --create-bucket-configuration LocationConstraint="$REGION"

echo "=== 開啟 S3 Versioning ==="
aws s3api put-bucket-versioning \
  --bucket "$BUCKET_NAME" \
  --versioning-configuration Status=Enabled

echo "=== Step 2: 建立 DynamoDB Table ==="
aws dynamodb create-table \
  --table-name "$DYNAMODB_TABLE" \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region "$REGION"

echo ""
echo "完成！接下來執行："
echo "  cd terraform/eks"
echo "  terraform init"
echo "  (會問是否 migrate state → 輸入 yes)"
