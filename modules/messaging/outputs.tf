output "eventhub_namespace_name" {
  description = "Suggested EventHub namespace name placeholder."
  value       = "evh-${var.resource_group_name}"
}

output "redis_name" {
  description = "Suggested Redis name placeholder."
  value       = "redis-${var.resource_group_name}"
}
