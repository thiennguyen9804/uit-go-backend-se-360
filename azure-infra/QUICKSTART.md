#  Quick Start Guide

```bash
# 1. Login Azure
az login

# 2. cd  terraform folder
cd azure-infra

# 3. Init Terraform
terraform init

# 4. Build and push images ( root project)
cd uit-go-backend-se-360
./build-and-push.sh

# 5. Deploy infrastructure
cd azure-infra
terraform apply
```

## Clear all 

```bash
terraform destroy
```



