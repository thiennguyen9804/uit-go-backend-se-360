output "key_vault_name" {
  description = "Suggested Key Vault name placeholder."
  value       = "kv-${lower(replace(var.resource_group_name, "-", ""))}"
}
