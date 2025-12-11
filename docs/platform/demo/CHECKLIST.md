#  Demo Checklist 

##  Trước Demo 

### 1. Prerequisites Check
- [ ] Azure CLI installed và login
- [ ] Terraform installed
- [ ] Docker installed (optional)
- [ ] Git configured
- [ ] Internet connection stable

### 2. Azure Setup
- [ ] Azure subscription active
- [ ] Service principal created
- [ ] Permissions verified (Contributor role)
- [ ] Test resource group creation

### 3. GitHub Setup
- [ ] Repository cloned
- [ ] GitHub Secrets configured:
  - [ ] `AZURE_CREDENTIALS` (Service principal JSON)
  - [ ] `ACR_NAME` (Azure Container Registry name)
  - [ ] `AZURE_RG_NAME` (Resource Group name)
  - [ ] `ACA_SUBNET_ID` (Subnet ID cho Container Apps)
- [ ] Branch protection rules (optional)

### 4. Test Run
- [ ] Chạy demo script 1 lần để test
- [ ] Verify infrastructure creation
- [ ] Test service deployment
- [ ] Clean up test resources

##  Ngày Demo 

### 1. Environment Check
- [ ] Azure login verified
- [ ] Subscription set correctly
- [ ] Internet connection stable
- [ ] Terminal/IDE ready

### 2. Backup Plan
- [ ] Screenshots của các bước (nếu demo fail)
- [ ] Pre-recorded video (backup)
- [ ] Documentation ready để show

### 3. Resources Ready
- [ ] Demo script executable
- [ ] Service templates ready
- [ ] Documentation open
- [ ] GitHub Actions page ready

##  Trong Demo

### Phase 1: Setup Infrastructure
- [ ] Show Terraform modules structure
- [ ] Explain Infrastructure as Code
- [ ] Run terraform init/plan/apply
- [ ] Show created resources

### Phase 2: Create Service
- [ ] Run create-service script
- [ ] Show generated files
- [ ] Explain service.yml
- [ ] Show validation

### Phase 3: Deploy
- [ ] Show GitHub Actions workflow
- [ ] Explain auto-discovery
- [ ] Show build process
- [ ] Show deployment

### Phase 4: Verify
- [ ] Show deployed service
- [ ] Test health endpoint
- [ ] Show logs
- [ ] Show metrics

##  Sau Demo

### 1. Cleanup (Optional)
```bash
# Xóa test resources nếu cần
az group delete --name rg-demo-se360 --yes --no-wait
```

### 2. Documentation
- [ ] Share documentation links
- [ ] Answer questions
- [ ] Provide contact info


