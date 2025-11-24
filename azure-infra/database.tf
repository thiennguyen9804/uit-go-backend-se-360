locals {
  service_databases = [
    "user-service-db",
    "driver-service-db",
    "trip-service-db",
  ]
}


# 1. Azure MSSQL Logical Server
resource "azurerm_mssql_server" "main" {
  name                = "sqlserver-microservice-tf"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  version             = "12.0"

  administrator_login          = var.db_admin_username
  administrator_login_password = var.db_admin_password
}

resource "azurerm_mssql_firewall_rule" "allow_azure_services" {
  name             = "AllowAzureServices"
  server_id        = azurerm_mssql_server.main.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}


# 2. Azure MSSQL Databases
resource "azurerm_mssql_database" "service_dbs" {
  for_each = toset(local.service_databases)

  name      = each.key
  server_id = azurerm_mssql_server.main.id

  sku_name = "Basic"
}

# 3. Private DNS Zone 
resource "azurerm_private_dns_zone" "sql_server" {
  name                = "privatelink.database.windows.net"
  resource_group_name = azurerm_resource_group.main.name
}

# 4. Private Endpoint
resource "azurerm_private_endpoint" "sql_server" {
  name                = "pe-sqlserver"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  subnet_id           = azurerm_subnet.db.id

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

# Output Database Hostname
output "db_hostname" {
  description = "The FQDN of the Azure SQL Server "
  value       = azurerm_mssql_server.main.fully_qualified_domain_name
  sensitive   = true
}