
data "azurerm_key_vault_secret" "db_password_secret" {
  name         = "db-admin-password"
  key_vault_id = azurerm_key_vault.main.id
}

locals {
  services = {
    "user-service"         = { port = 8080, db_name = "user-service-db", external = false },
    "driver-service"       = { port = 8082, db_name = "driver-service-db", external = false },
    "trip-service"         = { port = 8081, db_name = "trip-service-db", external = false },
    "matching-service"     = { port = 8083, db_name = null, external = false },
    "notification-service" = { port = 8084, db_name = null, external = false },
    "api-gateway"          = { port = 9000, db_name = null, external = true },
  }

  kafka_bootstrap_server = format("%s.servicebus.windows.net:9093", azurerm_eventhub_namespace.kafka.name)
  redis_hostname         = azurerm_redis_cache.main.hostname
  redis_port             = azurerm_redis_cache.main.port
}

# --- Microservices ---
resource "azurerm_container_app" "microservices" {
  for_each = local.services

  name                         = each.key
  container_app_environment_id = azurerm_container_app_environment.main.id
  resource_group_name          = azurerm_resource_group.main.name
  revision_mode                = "Single"

  # Attach the User Assigned Identity created in infra
  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.aca_identity.id]
  }

  registry {
    server   = azurerm_container_registry.main.login_server
    identity = azurerm_user_assigned_identity.aca_identity.id
  }

  template {
    container {
      name   = each.key
      image  = "${azurerm_container_registry.main.login_server}/${each.key}:latest"
      cpu    = 0.5
      memory = "1.0Gi"

      env {
        name  = "ASPNETCORE_ENVIRONMENT"
        value = "Production"
      }

      dynamic "env" {
        for_each = each.value.db_name != null ? [1] : []
        content {
          name = "DB_CONNECTION_STRING"
          value = format(
            "Server=%s;Database=%s;User ID=%s;Password=%s;",
            azurerm_mssql_server.main.fully_qualified_domain_name,
            each.value.db_name,
            var.db_admin_username,
            data.azurerm_key_vault_secret.db_password_secret.value
          )
        }
      }

      dynamic "env" {
        for_each = contains(["trip-service", "notification-service"], each.key) ? [1] : []
        content {
          name  = "KAFKA_BOOTSTRAP_SERVERS"
          value = local.kafka_bootstrap_server
        }
      }

      dynamic "env" {
        for_each = contains(["trip-service", "notification-service"], each.key) ? [1] : []
        content {
          name  = "KAFKA_SASL_USERNAME"
          value = "$ConnectionString"
        }
      }

      dynamic "env" {
        for_each = contains(["trip-service", "notification-service"], each.key) ? [1] : []
        content {
          name  = "KAFKA_SASL_PASSWORD"
          value = azurerm_eventhub_authorization_rule.kafka_send_listen.primary_connection_string
        }
      }

      dynamic "env" {
        for_each = contains(["trip-service", "notification-service"], each.key) ? [1] : []
        content {
          name  = "KAFKA_SECURITY_PROTOCOL"
          value = "SASL_SSL"
        }
      }

      dynamic "env" {
        for_each = contains(["trip-service", "notification-service"], each.key) ? [1] : []
        content {
          name  = "KAFKA_SASL_MECHANISM"
          value = "PLAIN"
        }
      }

      dynamic "env" {
        for_each = contains(["trip-service", "driver-service"], each.key) ? [1] : []
        content {
          name  = "REDIS_HOST"
          value = local.redis_hostname
        }
      }

      dynamic "env" {
        for_each = contains(["trip-service", "driver-service"], each.key) ? [1] : []
        content {
          name  = "REDIS_PORT"
          value = tostring(local.redis_port)
        }
      }

      dynamic "env" {
        for_each = contains(["trip-service", "driver-service"], each.key) ? [1] : []
        content {
          name  = "REDIS_PASSWORD"
          value = azurerm_redis_cache.main.primary_access_key
        }
      }
    }
  }

  ingress {
    external_enabled = each.value.external
    target_port      = each.value.port
    transport        = "auto"

    traffic_weight {
      percentage      = 100
      latest_revision = true
    }
  }

  # Ensure role assignments exist before creating apps so ACR pull / KV access works
  depends_on = [
    azurerm_role_assignment.aca_env_acr_pull,
    azurerm_role_assignment.aca_key_vault_access
  ]
}

output "api_gateway_url" {
  description = "Public URL for the API Gateway."
  value       = azurerm_container_app.microservices["api-gateway"].ingress[0].fqdn
}
