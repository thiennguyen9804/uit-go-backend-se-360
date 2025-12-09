terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.6"
    }
  }
  backend "azurerm" {
      resource_group_name  = "rg-terraform-state"
      storage_account_name = "sttfstate02b090"
      container_name       = "tfstate"
      key                  = "complete-demo.terraform.tfstate"
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "this" {
  name     = var.resource_group_name
  location = var.location
}

# Optional network creation
module "network" {
  source              = "../../modules/network"
  count               = var.create_network ? 1 : 0
  resource_group_name = azurerm_resource_group.this.name
  location            = var.location
  vnet_address_space  = var.vnet_address_space
  aca_subnet_address_space = var.aca_subnet_address_space
  db_subnet_address_space  = var.db_subnet_address_space
  tags                = var.tags
}

# Container registry
module "acr" {
  source              = "../../modules/container_registry"
  resource_group_name = azurerm_resource_group.this.name
  location            = var.location
  tags                = var.tags
}

# Container Apps environment - uses created subnet if network created
module "aca_env" {
  source              = "../../modules/container_app_env"
  resource_group_name = azurerm_resource_group.this.name
  location            = var.location
  aca_subnet_id       = var.create_network ? module.network[0].aca_subnet_id : var.aca_subnet_id
  tags                = var.tags
}

# Deploy service (optional)
module "service" {
  source                       = "../../modules/service_container"
  services                     = { (var.service_key) = { port = var.service_port, external = var.external } }
  container_app_environment_id = module.aca_env.container_app_environment_id
  resource_group_name          = azurerm_resource_group.this.name
  identity_id                  = module.aca_env.aca_identity_id
  acr_login_server             = module.acr.acr_login_server
  db_hostname                  = var.db_hostname
  db_admin_username            = var.db_admin_username
  db_admin_password            = var.db_admin_password
  kafka_bootstrap_server       = var.kafka_bootstrap_server
  kafka_connection_string      = var.kafka_connection_string
  redis_hostname               = var.redis_hostname
  redis_port                   = var.redis_port
  redis_password               = var.redis_password
  tags                         = var.tags
  count                        = var.deploy_service ? 1 : 0
}

# Grant the ACA user-assigned identity permission to pull from ACR
resource "azurerm_role_assignment" "aca_env_acr_pull" {
  scope                = module.acr.acr_id
  role_definition_name = "AcrPull"
  principal_id         = module.aca_env.aca_identity_principal_id
}
