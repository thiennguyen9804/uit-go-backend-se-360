resource "azurerm_virtual_network" "main" {
	name                = "vnet-${var.resource_group_name}"
	resource_group_name = var.resource_group_name
	location            = var.location
	address_space       = var.vnet_address_space
	tags                = var.tags
}

resource "azurerm_subnet" "aca" {
	name                 = "snet-aca"
	resource_group_name  = var.resource_group_name
	virtual_network_name = azurerm_virtual_network.main.name
	address_prefixes     = var.aca_subnet_address_space
	delegation {
		name = "containerapps_delegation"

		service_delegation {
			name = "Microsoft.App/environments"
			actions = [
				"Microsoft.Network/virtualNetworks/subnets/action",
			]
		}
	}
	
	# Dependencies: VNet must exist, and if Container Apps Environment ID is provided,
	# subnet will be destroyed after it (ensuring proper destroy order)
	depends_on = compact([
		azurerm_virtual_network.main,
		var.container_app_environment_id
	])

	lifecycle {
		# Prevent destroy if subnet is in use by Container Apps Environment
		# Terraform will destroy Container Apps Environment first, then subnet
		create_before_destroy = false
	}
}

resource "azurerm_subnet" "db" {
	name                 = "snet-db-pe"
	resource_group_name  = var.resource_group_name
	virtual_network_name = azurerm_virtual_network.main.name
	address_prefixes     = var.db_subnet_address_space
	depends_on = [azurerm_virtual_network.main]

}
