**Self-Service Platform: CI/CD + Terraform module**

- **Purpose**: Provide a reusable Terraform composition and GitHub Actions workflows so a developer can build a service into ACR and deploy it into this project's infrastructure with minimal effort.

- **Important**: This work does not modify `azure-infra`. All new CI/TF entrypoints for self-service live under `modules/self_service` and workflows in `.github/workflows`. The example reuses existing modules in `modules/` (ACR, Container Apps environment, service deployment).

Required GitHub repository secrets (set these in your repo settings -> Secrets):
- `ACR_NAME` or `ACR_LOGIN_SERVER` : ACR identifier used in workflows (repo uses `ACR_NAME` in `ci-cd.yml`).
- `ACR_USERNAME` / `ACR_PASSWORD` (optional): used by some workflows; repo supports `az acr login` and docker login.
- `AZURE_CREDENTIALS` : JSON from `az ad sp create-for-rbac --sdk-auth` used by `azure/login` action. (Consider switching to GitHub OIDC for improved security.)
- Terraform remote state secrets used by `azure-infra` (only when running full infra): `TF_STATE_RESOURCE_GROUP`, `TF_STATE_STORAGE_ACCOUNT`, `TF_STATE_CONTAINER`, `TF_STATE_KEY`.

Exact workflow inputs (for manual runs)
- Workflow: `CI/CD` (`.github/workflows/ci-cd.yml`) — supports `workflow_dispatch` with these inputs:
   - `service_path` (string, default `driver-service`): path to the folder containing the `Dockerfile`.
   - `image_name` (string, default `driver-service:latest`): tag to push to ACR (without registry host prefix; the workflow will prefix with the ACR login).
   - `terraform_dir` (string, default `modules/self_service/examples`): folder where Terraform will run.
   - `aca_subnet_id` (string): subnet id for Container Apps environment (required by `container_app_env` module).
   - `service_key` (string, default `driver-service`): service name used by the `service_container` module and image name.
   - `service_port` (number, default `80`): port the service listens on.
   - `external` (bool, default `true`): whether the service should be externally reachable.

How the dispatch uses these inputs
- The `self-service-deploy` job (runs only for manual `workflow_dispatch`) will:
   1. Build the Docker image from `service_path` and tag it as `<ACR_NAME>.azurecr.io/${{ inputs.image_name }}`.
   2. Push the image to ACR using `az acr login`.
   3. Run Terraform in `terraform_dir` with variables `service_key`, `aca_subnet_id`, `service_port`, and `external` supplied from inputs.

Quick manual demo (recommended script to present to your teacher)

Prereqs (on repo / GitHub):
- Repo secrets set: `AZURE_CREDENTIALS`, `ACR_NAME` (and Terraform backend secrets if you plan to run `azure-infra`).
- Have a subnet id for Container Apps (`aca_subnet_id`) that the project can use, or create one with the `network` module first.

Demo script you can run live (present these steps):

1) Build & push locally (optional verification step):

```bash
# from repo root, example using driver-service
SERVICE=driver-service
IMAGE_TAG=${ACR_NAME}.azurecr.io/${SERVICE}:latest

# Build
docker build -t "$IMAGE_TAG" "$SERVICE"

# Login to ACR from your machine (requires az CLI and that your account can access the registry)
az login
az acr login --name "$ACR_NAME"

# Push
docker push "$IMAGE_TAG"
```

2) Run the CI/CD manual dispatch (via GitHub Actions UI)

- Go to the repository -> Actions -> `CI/CD` workflow -> `Run workflow`.
- Fill the inputs:
   - `service_path`: `driver-service`
   - `image_name`: `driver-service:latest`
   - `terraform_dir`: `modules/self_service/examples`
   - `aca_subnet_id`: `<YOUR_SUBNET_ID>`
   - `service_key`: `driver-service`
   - `service_port`: `80`
   - `external`: `true`
- Click `Run workflow`.

3) What to show to your teacher during the demo
- Show the Running Action log: the `self-service-deploy` job steps (Checkout → Azure Login → Build/push → Terraform Init/Plan/Apply).
- Highlight the `Build and push image` step where the image tag is created and pushed to ACR.
- Show the Terraform plan and apply output — explain which modules are being used (`container_registry`, `container_app_env`, `service_container`) and which variables were injected from the workflow inputs.
- After apply completes, show outputs from `modules/self_service/examples` (if any) and verify the service is reachable (if `external=true`) by the host/port shown or by running `az containerapp show` or checking Container Apps ingress.

Local Terraform test (if you prefer to test without Actions):

```bash
cd modules/self_service/examples
terraform init
terraform plan -var="service_key=driver-service" -var="aca_subnet_id=<SUBNET_ID>" -var="service_port=80" -var="external=true"
# inspect plan, then:
terraform apply -auto-approve -var="service_key=driver-service" -var="aca_subnet_id=<SUBNET_ID>" -var="service_port=80" -var="external=true"
```

Operational notes & recommendations
- Consider switching to GitHub OIDC for Azure authentication to avoid long-lived `AZURE_CREDENTIALS` secrets. The repo already grants `id-token: write` permission in `ci-cd.yml` which helps enable OIDC flows.
- Limit who can run `workflow_dispatch` on sensitive branches (protect `main` or require approvals) so only authorized developers can run deploys.
- Add pre-deploy checks (unit tests or integration test steps) to the workflow to prevent broken images from being deployed.

If you want, I will:
- Add a ready-to-use `tfvars.example` for `modules/self_service/examples` that includes placeholders for `aca_subnet_id` and `service_key`.
- Convert the workflow to OIDC-based auth (remove `AZURE_CREDENTIALS`) and provide exact steps to set up the Azure AD trust.
- Add a short demo script file `scripts/demo_selfservice.sh` that automates the build/push/dispatch sequence for live demos.


**Local Onboarding & quick start (manual Terraform)**
- **Purpose**: Provision infrastructure using Terraform yourself, then build/push images with `./build-and-push.sh`, and finally deploy with the repo's GitHub Actions (or run Terraform locally to apply the example changes).

Manual provisioning options:
- Quick per-example (recommended for single-service testing): use `modules/self_service/examples` as a Terraform root.
- Full demo provisioning (Resource Group, optional VNet, ACR, ACA env, optional service): use `provision/complete_demo` root.

Prereqs (local machine):
```
az login
az account set --subscription <YOUR_SUBSCRIPTION_ID>
terraform --version
docker --version
```

Provisioning step-by-step (example: use the full demo root and create network):

```
# 1) initialize and plan
cd provision/complete_demo
terraform init
terraform plan -var='resource_group_name=rg-demo' -var='location=eastasia' -var='create_network=true'

# inspect plan, then apply when ready
terraform apply -var='resource_group_name=rg-demo' -var='location=eastasia' -var='create_network=true' -var='deploy_service=false' -auto-approve
```


Build & push images (after ACR exists):

```
# get ACR login server from terraform outputs (run in the root you applied)
terraform output -raw acr_login_server

# set ACR_NAME (short name) and build/push
export ACR_NAME=myregistry   # e.g. myregistry.azurecr.io
export PROJECT_ROOT=$(pwd)/../..
../../build-and-push.sh
```

Deploy via GitHub Actions (manual dispatch):
- Use the `CI/CD` workflow from the Actions UI and set `terraform_dir` to `modules/self_service/examples` (or your chosen root). The workflow builds/pushes (if needed) and runs Terraform in the specified `terraform_dir` using the inputs you provide.

Notes:
- We removed local wrapper scripts by design: you run Terraform yourself to provision the environment and then use `./build-and-push.sh` for images. The GitHub Actions workflows remain and will use the same Terraform modules for authoritative runs and plan artifacts.
- `tfvars.auto.tfvars` is intentionally provided as an example; replace placeholders with your values and do NOT commit secrets.

**Next (optional) security tasks**
- Enable GitHub OIDC for Azure to avoid long-lived `AZURE_CREDENTIALS` secrets: create an Azure AD workload identity federated credential for the repo/service principal and update GitHub workflow to use `azure/login` with OIDC. I can script these steps for you.
- Add branch protection rules on `main` and require Terraform plan approval before `apply` in GitHub Actions.


