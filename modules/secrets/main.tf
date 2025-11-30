data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "main" {
	name                       = "kv-${lower(replace(var.resource_group_name, "-", ""))}"
	location                   = var.location
	resource_group_name        = var.resource_group_name
	tenant_id                  = data.azurerm_client_config.current.tenant_id
	sku_name                   = "standard"
	soft_delete_retention_days = 7
	tags                       = var.tags
}

resource "azurerm_key_vault_secret" "db_password" {
	name         = "db-admin-password"
	value        = var.db_admin_password
	key_vault_id = azurerm_key_vault.main.id
}

resource "azurerm_role_assignment" "aca_key_vault_access" {
	scope                = azurerm_key_vault.main.id
	role_definition_name = "Key Vault Secrets User"
	principal_id         = var.aca_identity_principal_id
}

resource "azurerm_role_assignment" "aca_env_acr_pull" {
	scope                = var.acr_id
	role_definition_name = "AcrPull"
	principal_id         = var.aca_identity_principal_id
}

output "key_vault_id" {
	value = azurerm_key_vault.main.id
}
