#!/bin/bash
# Script to setup Terraform backend (Storage Account for remote state)

set -euo pipefail

# Configuration
RESOURCE_GROUP_NAME="${TF_STATE_RESOURCE_GROUP:-rg-terraform-state}"
# Generate unique storage account name if not provided
if [ -z "${TF_STATE_STORAGE_ACCOUNT:-}" ]; then
    RANDOM_SUFFIX=$(openssl rand -hex 3 2>/dev/null || echo $(date +%s | tail -c 6))
    STORAGE_ACCOUNT_NAME="sttfstate${RANDOM_SUFFIX}"
else
    STORAGE_ACCOUNT_NAME="${TF_STATE_STORAGE_ACCOUNT}"
fi
CONTAINER_NAME="${TF_STATE_CONTAINER:-tfstate}"
LOCATION="${LOCATION:-eastasia}"

echo "🔧 Setting up Terraform backend..."
echo ""
echo "Configuration:"
echo "  Resource Group: $RESOURCE_GROUP_NAME"
echo "  Storage Account: $STORAGE_ACCOUNT_NAME"
echo "  Container: $CONTAINER_NAME"
echo "  Location: $LOCATION"
echo ""

# Check if already exists
if az group show --name "$RESOURCE_GROUP_NAME" &>/dev/null; then
    echo "✅ Resource Group '$RESOURCE_GROUP_NAME' already exists"
else
    echo "📦 Creating Resource Group..."
    az group create \
        --name "$RESOURCE_GROUP_NAME" \
        --location "$LOCATION"
    echo "✅ Resource Group created"
fi

# Check if storage account exists
if az storage account show --name "$STORAGE_ACCOUNT_NAME" --resource-group "$RESOURCE_GROUP_NAME" &>/dev/null; then
    echo "✅ Storage Account '$STORAGE_ACCOUNT_NAME' already exists"
else
    echo "📦 Creating Storage Account..."
    # Storage account name must be globally unique and 3-24 chars, lowercase alphanumeric
    az storage account create \
        --name "$STORAGE_ACCOUNT_NAME" \
        --resource-group "$RESOURCE_GROUP_NAME" \
        --location "$LOCATION" \
        --sku Standard_LRS \
        --kind StorageV2
    echo "✅ Storage Account created"
fi

# Check if container exists
if az storage container show \
    --name "$CONTAINER_NAME" \
    --account-name "$STORAGE_ACCOUNT_NAME" \
    --auth-mode login &>/dev/null; then
    echo "✅ Container '$CONTAINER_NAME' already exists"
else
    echo "📦 Creating Storage Container..."
    az storage container create \
        --name "$CONTAINER_NAME" \
        --account-name "$STORAGE_ACCOUNT_NAME" \
        --auth-mode login
    echo "✅ Container created"
fi

echo ""
echo ""
echo "✅ Terraform backend setup complete!"
echo ""
echo "📝 Update main.tf with this storage account name:"
echo "   storage_account_name = \"$STORAGE_ACCOUNT_NAME\""
echo ""
echo "💡 Then run:"
echo "   cd provision/complete_demo"
echo "   terraform init"
echo ""

