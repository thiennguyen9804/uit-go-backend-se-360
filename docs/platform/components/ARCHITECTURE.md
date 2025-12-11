#  Self-Service Platform Architecture

## Tổng Quan Kiến Trúc

Nền tảng Self-Service được thiết kế với các nguyên tắc:
- **Modularity**: Modules Terraform có thể tái sử dụng
- **Automation**: Tự động hóa toàn bộ quy trình từ code đến production
- **Safety**: Validation, testing, approval workflows
- **Simplicity**: Developer chỉ cần tạo `service.yml` và push code

## 🔄 Deployment Flow

```
┌─────────────────────────────────────────────────────────────┐
│                    Developer Workflow                        │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
        ┌───────────────────────────────────┐
        │  1. Create Service                │
        │     ./scripts/create-service.sh   │
        └──────────────┬────────────────────┘
                       │
                       ▼
        ┌───────────────────────────────────┐
        │  2. Configure service.yml          │
        │     - Runtime config               │
        │     - Dependencies                 │
        │     - Environment variables        │
        └──────────────┬────────────────────┘
                       │
                       ▼
        ┌───────────────────────────────────┐
        │  3. Validate                       │
        │     ./scripts/validate-service.sh  │
        └──────────────┬────────────────────┘
                       │
                       ▼
        ┌───────────────────────────────────┐
        │  4. Commit & Push                  │
        │     git push origin main           │
        └──────────────┬────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│              GitHub Actions Workflow                         │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
        ┌───────────────────────────────────┐
        │  Job 1: Discover Service          │
        │  - Auto-detect from changes        │
        │  - Load service.yml                │
        └──────────────┬────────────────────┘
                       │
                       ▼
        ┌───────────────────────────────────┐
        │  Job 2: Validate                  │
        │  - Validate service.yml            │
        │  - Check Dockerfile                │
        └──────────────┬────────────────────┘
                       │
                       ▼
        ┌───────────────────────────────────┐
        │  Job 3: Build & Test              │
        │  - Setup build tools               │
        │  - Run tests                       │
        │  - Build Docker image              │
        │  - Push to ACR                     │
        └──────────────┬────────────────────┘
                       │
                       ▼
        ┌───────────────────────────────────┐
        │  Job 4: Terraform Plan             │
        │  - Init Terraform                  │
        │  - Generate plan                   │
        │  - Upload plan artifact            │
        └──────────────┬────────────────────┘
                       │
                       ▼
        ┌───────────────────────────────────┐
        │  Job 5: Terraform Apply           │
        │  - Download plan                   │
        │  - Apply changes                   │
        │  - Deploy to Container Apps        │
        └──────────────┬────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│                    Azure Infrastructure                      │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
        ┌───────────────────────────────────┐
        │  Container Apps                   │
        │  - Service deployed               │
        │  - Auto-scaling enabled           │
        │  - Health checks active            │
        └───────────────────────────────────┘
```

##  Terraform Modules Structure

### Module Hierarchy

```
modules/
├── self_service/
│   └── examples/              # Example Terraform root
│       ├── main.tf            # Main configuration
│       ├── variables.tf       # Input variables
│       └── network.tf         # Network (optional)
│
├── service_container/         # Service deployment module
│   ├── main.tf               # Container App resources
│   ├── variables.tf          # Module inputs
│   └── outputs.tf            # Module outputs
│
├── container_app_env/        # Container Apps environment
│   ├── main.tf               # ACA Environment
│   └── outputs.tf            # Environment outputs
│
├── container_registry/       # Azure Container Registry
│   ├── main.tf               # ACR resource
│   └── outputs.tf            # ACR outputs
│
└── network/                  # Networking
    ├── main.tf               # VNet, Subnets
    └── outputs.tf            # Network outputs
```

### Module Dependencies

```
service_container
    ├── depends on: container_app_env
    ├── depends on: container_registry
    └── uses: network (optional)

container_app_env
    └── uses: network (for subnet)

container_registry
    └── (standalone)
```

##  Security Architecture

### Authentication & Authorization

```
┌──────────────┐
│ GitHub       │
│ Actions      │
└──────┬───────┘
       │
       │ Azure Login
       ▼
┌──────────────┐
│ Azure AD     │
│ Service      │
│ Principal    │
└──────┬───────┘
       │
       │ RBAC
       ▼
┌──────────────┐
│ Azure        │
│ Resources    │
│ - ACR        │
│ - Container  │
│   Apps       │
└──────────────┘
```

### Secrets Management

- **GitHub Secrets**: `AZURE_CREDENTIALS`, `ACR_NAME`, `AZURE_RG_NAME`, `ACA_SUBNET_ID`
- **Azure Key Vault**: Database passwords, connection strings
- **Managed Identity**: Service-to-service authentication

##  Monitoring & Observability

### Metrics Collected

- **Deployment Metrics**:
  - Deployment success/failure rate
  - Deployment duration
  - Service availability

- **Runtime Metrics**:
  - CPU/Memory usage
  - Request rate
  - Error rate
  - Response time

### Logging

- **GitHub Actions Logs**: Deployment process
- **Container Apps Logs**: Application logs
- **Terraform Logs**: Infrastructure changes

##  Scaling Strategy

### Horizontal Scaling

- **Auto-scaling**: Based on CPU/Memory metrics
- **Scale-to-zero**: `min_replicas: 0` for cost optimization
- **Max replicas**: Configurable per service

### Vertical Scaling

- **CPU**: 0.25, 0.5, 1.0, 1.5, 2.0 vCPU
- **Memory**: 0.5Gi, 1.0Gi, 2.0Gi, 4.0Gi

## 🔄 Rollback Strategy

### Automatic Rollback

- Health check failures trigger rollback
- Previous revision automatically promoted

### Manual Rollback

```bash
az containerapp revision set-mode \
  --name <service> \
  --resource-group <rg> \
  --mode multiple \
  --traffic-weight <previous-revision>=100
```

---

**Last Updated**: $(date)

