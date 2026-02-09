# DevOps Interview Project

## 專案總覽

- **目標**：在 14 天內完成面試級 DevOps 專案  
- **技術棧**：
  - Docker  
  - Kubernetes (k3d / EKS)  
  - Helm  
  - GitHub Actions (CI/CD)  
  - Terraform (基礎設施自動化)  
  - Prometheus / Alertmanager (監控告警)  
- **核心工作流**：  
Git push → CI → Artifact (Docker image) → CD → Cluster → Monitoring

---

## Day1~Day7 精華

- **Day1**：專案骨架建立、k3d 本地 cluster 啟動、第一個 Nginx Pod 測試  
- **Day2**：Helm chart 初步部署、Ingress 配置、對外可訪問  
- **Day3~Day4**：Deployment、ReplicaSet、RollingUpdate、Rollback 測試  
- **Day5~Day6**：CI/CD 初步流程  
- Day6 成功建立 GitHub Actions 流程  
- push code → build Docker image → push Docker Hub  
- CD 嘗試 helm upgrade 部署到本機 k3d，但受網路限制無法自動執行  
- 手動部署流程：
  ```bash
  helm upgrade --install devops ./helm/nginx-chart \
    --namespace devops \
    --create-namespace \
    --set image.tag=<dockerhub-image-tag>
  ```

> ⚡ 前七天重點：建立可運行的本地 DevOps 環境，熟悉 Helm 部署、CI/CD 基本流程。

---

## Day8 CI/CD (詳細)

### 1️⃣ 目標
- 將 Day6 的手動 build & deploy 升級為 **自動化 CI 流程**  
- 拆分 CI 與 CD，展示 Artifact Flow  
- CD 設計為手動觸發，符合本機 k3d 限制

### 2️⃣ CI/CD 架構

#### CI（自動化產物）
- 觸發：`git push main`  
- 步驟：
1. Checkout 代碼
2. 設定 image tag (`commit SHA`)
3. 登入 Docker Hub
4. Build Docker Image
5. Push Image 到 Docker Hub

#### CD（部署）
- 觸發：手動 workflow_dispatch  
- 步驟：
1. Checkout 代碼
2. Setup kubectl + Helm
3. 將 CI 產生的 image tag 部署到 k3d cluster

> 💡 設計理由：
> - CI runner 在公網，k3d cluster 在本機，無法安全自動連線  
> - CD 手動觸發，符合業界 DevOps 分工  
> - Artifact 可追蹤、可回滾

### 3️⃣ CI/CD 流程圖
GitHub Push
│
▼
CI Job (build & push image)
│
▼ (artifact: commit SHA image)
CD Job (manual helm upgrade)
│
▼
Cluster / Helm release

### 4️⃣ Helm Values 設計
```yaml
image:
  repository: yourname/devops-app
  tag: "" # 部署時由 CI 輸出填入 commit SHA

```

### 5️⃣ 手動部署指令
- 安全與環境邊界（k3d 無法自動 CD）
```bash
helm upgrade --install devops ./helm/nginx-chart \
  --namespace devops \
  --create-namespace \
  --set image.tag=<commit-sha>
```

