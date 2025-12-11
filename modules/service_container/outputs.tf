output "api_gateway_url" {
  description = "Public URL for the API Gateway (if present in services map)."
  value       = try(azurerm_container_app.microservices["api-gateway"].ingress[0].fqdn, "")
}

output "container_app_fqdns" {
  description = "Map of service names to their FQDNs (if externally accessible)"
  value = {
    for k, v in azurerm_container_app.microservices : k => try(v.ingress[0].fqdn, "")
  }
}
