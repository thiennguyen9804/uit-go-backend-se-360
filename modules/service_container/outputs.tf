output "api_gateway_url" {
  description = "Public URL for the API Gateway (if present in services map)."
  value       = try(azurerm_container_app.microservices["api-gateway"].ingress[0].fqdn, "")
}
