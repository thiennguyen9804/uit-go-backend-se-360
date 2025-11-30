locals {
	service_databases = var.service_databases
}

resource "azurerm_mssql_server" "main" {
	name                = "sqlserver-${lower(replace(var.resource_group_name, "-", ""))}"
	resource_group_name = var.resource_group_name
	location            = var.location
	version             = "12.0"

	administrator_login          = var.db_admin_username
	administrator_login_password = var.db_admin_password
	tags                        = var.tags
}

resource "azurerm_mssql_firewall_rule" "allow_azure_services" {
	name      = "AllowAzureServices"
	server_id = azurerm_mssql_server.main.id
	start_ip_address = "0.0.0.0"
	end_ip_address   = "0.0.0.0"
}

resource "azurerm_mssql_database" "service_dbs" {
	for_each = toset(local.service_databases)

	name      = each.key
	server_id = azurerm_mssql_server.main.id
	sku_name  = "Basic"
}

resource "azurerm_private_dns_zone" "sql_server" {
	name                = "privatelink.database.windows.net"
	resource_group_name = var.resource_group_name
	tags                = var.tags
}

resource "azurerm_private_endpoint" "sql_server" {
	name                = "pe-sqlserver"
	location            = var.location
	resource_group_name = var.resource_group_name
	subnet_id           = var.db_subnet_id

	private_service_connection {
		name                           = "psc-sqlserver"
		private_connection_resource_id = azurerm_mssql_server.main.id
		is_manual_connection           = false
		subresource_names              = ["sqlServer"]
	}

	private_dns_zone_group {
		name                 = "default"
		private_dns_zone_ids = [azurerm_private_dns_zone.sql_server.id]
	}
}

output "db_hostname" {
	description = "The FQDN of the Azure SQL Server"
	value       = azurerm_mssql_server.main.fully_qualified_domain_name
	sensitive   = true
}
