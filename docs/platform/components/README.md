# 🏗️ Components & Architecture - Self-Service Platform

Tài liệu về kiến trúc và các thành phần của Self-Service Platform.

##  Tài Liệu

### Architecture
- **[Architecture](ARCHITECTURE.md)**: Kiến trúc chi tiết và các thành phần

##  Components Overview

### Terraform Modules
- `modules/self_service/`: Self-service Terraform modules
- `modules/service_container/`: Service deployment module
- `modules/container_app_env/`: Container Apps environment module
- `modules/container_registry/`: Azure Container Registry module
- `modules/network/`: Networking infrastructure module

### GitHub Workflows
- `.github/workflows/deploy-service.yml`: Main self-service deployment workflow
- `.github/workflows/approve-deployment.yml`: Approval workflow
- `.github/workflows/ci-cd.yml`: Build/test + Infrastructure deployment

### Scripts
- `scripts/create-service.sh`: Service generator
- `scripts/validate-service-config.sh`: Config validator
- `scripts/health-check.sh`: Health check tool
- `scripts/setup-terraform-backend.sh`: Backend setup

##  Architecture Documentation

Xem **[Architecture](ARCHITECTURE.md)** để biết chi tiết về:
- Deployment Flow
- Terraform Modules Structure
- Security Architecture
- Monitoring & Observability
- Scaling Strategy
- Rollback Strategy

---

**Need architecture details?** → [Architecture](ARCHITECTURE.md)

