output "resource_group_name" {
  value = azurerm_resource_group.this.name
}

output "location" {
  value = azurerm_resource_group.this.location
}

output "aca_subnet_id" {
  value = var.create_network ? module.network[0].aca_subnet_id : var.aca_subnet_id
}

output "acr_login_server" {
  value = module.acr.acr_login_server
}

output "service_fqdn" {
  value = var.deploy_service ? (module.acr.acr_login_server == "" ? "" : "${module.acr.acr_login_server}/${var.service_key}:latest") : ""
}
