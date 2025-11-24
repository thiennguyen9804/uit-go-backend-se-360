# Azure Infrastructure với Terraform

Tài liệu này hướng dẫn cách deploy và quản lý infrastructure trên Azure sử dụng Terraform.

##  Yêu cầu

- [Terraform](https://www.terraform.io/downloads) >= 1.0
- [Azure CLI](https://docs.microsoft.com/cli/azure/install-azure-cli) đã được cài đặt và login
- Azure subscription với quyền tạo resources
- Docker (để build và push images)

##  Bước 1: Setup ban đầu

### 1.1. Login vào Azure

```bash
az login
az account set --subscription <your-subscription-id>
```

### 1.2. Clone repository và vào thư mục terraform

```bash
cd azure-infra
```

### 1.3. Khởi tạo Terraform

```bash
terraform init
```

## Bước 2: Build và Push Docker Images

Trước khi deploy infrastructure,  cần build và push images lên Azure Container Registry:

```bash
cd uit-go-backend-se-360
./build-and-push.sh
```

Script này sẽ:
- Build tất cả microservices (.NET và Java)
- Push images lên ACR: `acrrgmicroservicevn.azurecr.io`

**Lưu ý:** Đảm bảo Docker đang chạy trước khi chạy script.

##  Bước 3: Deploy Infrastructure

### 3.1. Xem plan trước khi apply

```bash
cd azure-infra
terraform plan
```

### 3.2. Deploy tất cả resources

```bash
terraform apply
```

Terraform sẽ tạo:
- Resource Group
- Virtual Network và Subnets
- Azure Container Registry (ACR)
- Azure Container Apps Environment
- Azure SQL Server và Databases
- Azure Event Hubs (Kafka)
- Azure Cache for Redis
- Key Vault
- 6 Container Apps (microservices)

### 3.3. Xem outputs sau khi deploy

```bash
terraform output
```

Output quan trọng:
- `api_gateway_url`: Public URL của API Gateway
- `acr_login_server`: ACR server để push images

##  Cấu trúc Files

```
azure-infra/
├── main.tf              # VNet, Subnets, Resource Group
├── container_infra.tf   # ACR, Container Apps Environment
├── database.tf          # SQL Server, Databases
├── messaging.tf         # Event Hubs (Kafka), Redis
├── services.tf          # Container Apps (microservices)
├── secrets.tf           # Key Vault và secrets
├── variables.tf         # Variables
├── versions.tf          # Terraform provider versions
├── .gitignore           # Files to ignore in Git
├── README.md            # Documentation (file này)
└── scale-services.sh     # Script để scale services up/down
```

## 🔧 Variables

Các variables có thể override trong `terraform.tfvars` (không  commit):

```hcl
resource_group_name = "rg-microservice-vn"
location            = "East Asia"
db_admin_username   = "tfadmin"
db_admin_password   = "YourStrong@Passw0rd"
```

## Secrets Management

- Database password được lưu trong Azure Key Vault
- Container Apps sử dụng Managed Identity để access Key Vault
- ACR authentication sử dụng Managed Identity


