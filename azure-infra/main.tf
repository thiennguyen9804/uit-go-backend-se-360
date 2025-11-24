# 1. Resource Group
resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location
  tags = {
    Environment = "Development"
    Project     = "Microservices"
  }
}

# 2. Virtual Network (VNet) -  VPC
resource "azurerm_virtual_network" "main" {
  name                = "vnet-microservice"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  address_space       = var.vnet_address_space
}

# 3. Subnet for Azure Container Apps (ACA)
resource "azurerm_subnet" "aca" {
  name                 = "snet-aca"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = var.aca_subnet_address_space
  delegation {
    name = "containerapps_delegation"

    service_delegation {
      name = "Microsoft.App/environments"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/action"
      ]
    }
  }
}

# 4. Subnet for Private Endpoint của Database
resource "azurerm_subnet" "db" {
  name                 = "snet-db-pe"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = var.db_subnet_address_space
}

# Output VNet ID
output "vnet_id" {
  description = "The ID of the main Virtual Network."
  value       = azurerm_virtual_network.main.id
}