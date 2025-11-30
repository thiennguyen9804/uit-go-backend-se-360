resource "azurerm_log_analytics_workspace" "main" {
	name                = "log-aca-${lower(replace(var.resource_group_name, "-", ""))}"
	location            = var.location
	resource_group_name = var.resource_group_name
	sku                 = "PerGB2018"
	tags                = var.tags
}

resource "azurerm_container_app_environment" "main" {
	name                       = "aca-env-${lower(replace(var.resource_group_name, "-", ""))}"
	location                   = var.location
	resource_group_name        = var.resource_group_name
	log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id

	infrastructure_subnet_id = var.aca_subnet_id

	lifecycle {
		ignore_changes = [
			infrastructure_resource_group_name,
		]
	}

	tags = var.tags
}

resource "azurerm_user_assigned_identity" "aca_identity" {
	resource_group_name = var.resource_group_name
	location            = var.location
	name                = "id-aca-${lower(replace(var.resource_group_name, "-", ""))}"
}


