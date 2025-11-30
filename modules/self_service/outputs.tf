output "container_fqdn" {
  description = "FQDN assigned to the container group (if any)"
  value       = try(azurerm_container_group.this.fqdn, "")
}

output "resource_group" {
  description = "Resource group name used/created"
  value       = azurerm_resource_group.this.name
}
