output "vnet_id" {
  description = "ID of the created VNet."
  value       = azurerm_virtual_network.main.id
}

output "aca_subnet_id" {
  description = "ID of the ACA subnet."
  value       = azurerm_subnet.aca.id
}

output "db_subnet_id" {
  description = "ID of the DB subnet."
  value       = azurerm_subnet.db.id
}
