
## Tổng Quan Demo

Demo này trình bày **Self-Service Platform** từ đầu đến cuối, bắt đầu từ lúc **chưa có hạ tầng Azure**.


##  Chuẩn Bị Trước Demo

### 1. Prerequisites

```bash
# Kiểm tra các tools cần thiết
az --version          # Azure CLI
terraform --version   # Terraform
docker --version      # Docker (optional)
git --version         # Git
```

### 2. Azure Setup

```bash
# Login Azure
az login

# Set subscription
az account set --subscription <subscription-id>

# Verify
az account show

# Setup Terraform Backend (lần đầu tiên)
./scripts/setup-terraform-backend.sh
```

**Lưu ý**: Script `setup-terraform-backend.sh` sẽ tự động tạo Storage Account cho Terraform state. Nếu Storage Account name đã bị dùng, script sẽ tự động generate tên unique.

### 3. GitHub Secrets

Đảm bảo các secrets sau đã được set trong GitHub:
- `AZURE_CREDENTIALS`: Service principal credentials
- `ACR_NAME`: Azure Container Registry name
- `ACA_SUBNET_ID`: Subnet ID cho Container Apps (sẽ được tạo)

##  Demo Manual (Step-by-Step)

Demo từng bước một cách chi tiết:

### BƯỚC 1: Setup Terraform Backend (1-2 phút)

**Lần đầu tiên**, cần setup Storage Account cho Terraform state:

```bash
# Tự động tạo Storage Account và Container
./scripts/setup-terraform-backend.sh
```

Script sẽ:
- Tạo Resource Group: `rg-terraform-state`
- Tạo Storage Account với tên unique (ví dụ: `sttfstate02b090`)
- Tạo Container: `tfstate`
- Hiển thị tên Storage Account để update vào `main.tf`

**Lưu ý**: Nếu Storage Account đã được tạo, script sẽ skip bước này.

### BƯỚC 2: Setup Hạ Tầng Azure (5-10 phút)

```bash
cd provision/complete_demo

# Initialize Terraform (sẽ dùng remote state từ Storage Account)
terraform init

# Plan infrastructure
terraform plan \
  -var="resource_group_name=rg-demo-se360" \
  -var="location=eastasia" \
  -var="create_network=true" \
  -var="deploy_service=false"

# Apply (tạo hạ tầng)
terraform apply \
  -var="resource_group_name=rg-demo-se360" \
  -var="location=eastasia" \
  -var="create_network=true" \
  -var="deploy_service=false" \
  -auto-approve

# Lấy outputs
ACR_LOGIN_SERVER=$(terraform output -raw acr_login_server)
ACA_SUBNET_ID=$(terraform output -raw aca_subnet_id)

echo "ACR: $ACR_LOGIN_SERVER"
echo "Subnet ID: $ACA_SUBNET_ID"

# Lưu các giá trị này cho GitHub Secrets
echo " Set GitHub Secrets:"
echo "   ACR_NAME=$(echo $ACR_LOGIN_SERVER | cut -d'.' -f1)"
echo "   ACA_SUBNET_ID=\"$ACA_SUBNET_ID\""

cd ../..
```

**Giải thích:**
- Terraform tạo hạ tầng Azure: Resource Group, VNet, ACR, Container Apps Environment
- Modules có thể tái sử dụng, dễ maintain
- Infrastructure as Code: Version control, reproducible

### BƯỚC 3: Tạo Service Mới (2 phút)

```bash
# Tạo service từ template
./scripts/create-service.sh demo-service maven

# Xem cấu trúc
tree demo-service -L 2
# hoặc
ls -la demo-service/
```

**Giải thích:**
- Script tự động tạo cấu trúc service
- Tạo Dockerfile, source code template, service.yml
- Phục vụ cho demo 

### BƯỚC 4: Review Service Configuration (1 phút)

```bash
# Xem service.yml
cat demo-service/service.yml
```

**Giải thích:**
- File `service.yml` định nghĩa toàn bộ cấu hình service
- Developer chỉ cần chỉnh sửa file này
- Platform tự động đọc và apply config

### BƯỚC 5: Validate Configuration (1 phút)

```bash
# Validate service.yml
./scripts/validate-service-config.sh demo-service/service.yml
```

**Giải thích:**
- Validation đảm bảo config đúng format
- Phát hiện lỗi sớm, trước khi deploy
- Giảm thiểu lỗi production

### BƯỚC 6: Commit và Push (1 phút)

```bash
# Add service
git add demo-service/

# Commit
git commit -m "feat: add demo-service"

# Push (trigger GitHub Actions)
git push origin production
```

**Giải thích:**
- Push code trigger GitHub Actions tự động
- Không cần manual steps
- CI/CD pipeline tự động chạy

### BƯỚC 7: Monitor Deployment (2-3 phút)

1. **Vào GitHub Actions**:
   ```
   https://github.com/<repo>/actions
   ```

2. **Xem workflow đang chạy**:
   - Discover Service
   - Validate Service Config
   - Build and Test
   - Terraform Plan
   - Terraform Apply

3. **Giải thích từng bước**:
   - **Discover**: Tự động phát hiện service từ git changes
   - **Validate**: Kiểm tra service.yml và Dockerfile
   - **Build**: Build Docker image, push lên ACR
   - **Deploy**: Terraform apply để deploy lên Azure

### BƯỚC 8: Verify Deployment (2 phút)

```bash
# Check service status
az containerapp show \
  --name demo-service \
  --resource-group rg-demo-se360 \
  --query "properties.configuration.ingress.fqdn" \
  -o tsv

# Test health endpoint
curl https://<service-url>/actuator/health

# View logs
az containerapp logs show \
  --name demo-service \
  --resource-group rg-demo-se360 \
  --follow
```

**Giải thích:**
- Service đã được deploy thành công
- Health check endpoint hoạt động
- Logs có thể xem real-time

##  Điểm Nổi Bật Để Trình Bày

### 1. Tự Động Hóa Hoàn Toàn
-  Từ code đến production chỉ với `git push`
-  Không cần manual steps
-  Developer tập trung vào code, không lo infrastructure

### 2. An Toàn và Đáng Tin Cậy
-  Multi-level validation
-  Automated testing
-  Terraform plan review
-  Health checks sau deployment

### 3. Modular và Tái Sử Dụng
-  Terraform modules có thể tái sử dụng
-  Service template cho nhiều languages
-  Dễ dàng mở rộng và maintain

### 4. Developer-Friendly
-  Dev mới chỉ cần:
  1. Tạo service: `./scripts/create-service.sh my-service` (cho demo)
  2. Cấu hình: Chỉnh sửa `service.yml`
  3. Deploy: `git push`
-  Documentation đầy đủ
-  Quick start guide

### 5. Cost Optimization
-  Scale-to-zero (min_replicas: 0)
-  Auto-scaling based on load
-  Resource limits configurable

