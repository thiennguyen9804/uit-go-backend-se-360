output "container_app_environment_id" {
  description = "ACA environment id"
  value       = azurerm_container_app_environment.main.id
}

output "aca_identity_id" {
  description = "User assigned identity resource id"
  value       = azurerm_user_assigned_identity.aca_identity.id
}

output "aca_identity_principal_id" {
  description = "Principal id for the user assigned identity"
  value       = azurerm_user_assigned_identity.aca_identity.principal_id
}

output "log_analytics_workspace_id" {
  description = "Log Analytics workspace id used by ACA."
  value       = azurerm_log_analytics_workspace.main.id
}
