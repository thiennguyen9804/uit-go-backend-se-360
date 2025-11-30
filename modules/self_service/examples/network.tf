// Optional: create a VNet and subnets for the examples when `create_network = true`
locals {
  create_network = var.create_network
}

module "network" {
  source               = "../../network"
  count                = local.create_network ? 1 : 0
  resource_group_name  = azurerm_resource_group.this.name
  location             = var.location
  vnet_address_space   = var.vnet_address_space
  aca_subnet_address_space = var.aca_subnet_address_space
  db_subnet_address_space  = var.db_subnet_address_space
  tags                 = var.tags
}
