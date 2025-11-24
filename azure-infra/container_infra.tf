# 1. Azure Container Registry (ACR)
resource "azurerm_container_registry" "main" {
  name                = "acr${lower(replace(var.resource_group_name, "-", ""))}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  sku                 = "Basic"
  admin_enabled       = true
}

# 2. Log Analytics Workspace 
resource "azurerm_log_analytics_workspace" "main" {
  name                = "log-aca-${lower(replace(var.resource_group_name, "-", ""))}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "PerGB2018"
}

# 3. Azure Container Apps Environment (ACA Environment)
resource "azurerm_container_app_environment" "main" {
  name                       = "aca-env-microservice"
  location                   = azurerm_resource_group.main.location
  resource_group_name        = azurerm_resource_group.main.name
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id

  infrastructure_subnet_id = azurerm_subnet.aca.id

  lifecycle {
    ignore_changes = [
      infrastructure_resource_group_name
    ]
  }
}

# 4. Managed Identity for ACA Environment 
resource "azurerm_user_assigned_identity" "aca_identity" {
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  name                = "id-aca-microservice"
}


# Output ACR Login Server
output "acr_login_server" {
  description = "The login server for the Azure Container Registry."
  value       = azurerm_container_registry.main.login_server
}