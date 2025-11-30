output "sql_server_name" {
  description = "Suggested SQL server name placeholder."
  value       = "sqlserver-${var.resource_group_name}"
}

output "database_names" {
  description = "List of database names configured for services."
  value       = var.service_databases
}
