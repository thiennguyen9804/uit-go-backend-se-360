provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "this" {
  name     = var.resource_group_name
  location = var.location
}

// Create or reuse an ACR
module "acr" {
  source              = "../container_registry"
  resource_group_name = azurerm_resource_group.this.name
  location            = var.location
  tags                = var.tags
}

// Create or reuse a Container Apps environment (requires a subnet id)
module "aca_env" {
  source              = "../container_app_env"
  resource_group_name = azurerm_resource_group.this.name
  location            = var.location
  aca_subnet_id       = local.aca_subnet_id_final
  tags                = var.tags
}

// Deploy the service into Container Apps using the existing service_container module
module "service" {
  source                       = "../service_container"
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
}

output "service_acr" {
  description = "ACR login server used for the pushed image"
  value       = module.acr.acr_login_server
}

output "service_fqdn" {
  description = "(If external) the hostname to reach the service"
  value       = "${module.acr.acr_login_server}/${var.service_key}:latest"
}
