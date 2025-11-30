resource "azurerm_container_registry" "main" {
	name                = "acr${lower(replace(var.resource_group_name, "-", ""))}"
	resource_group_name = var.resource_group_name
	location            = var.location
	sku                 = var.sku
	admin_enabled       = true
	tags                = var.tags
}

output "acr_login_server" {
	value       = azurerm_container_registry.main.login_server
	description = "ACR login server"
}

output "acr_id" {
	value       = azurerm_container_registry.main.id
	description = "ACR resource id"
}
