resource "azurerm_container_app" "microservices" {
  for_each = var.services

  name                         = each.key
  container_app_environment_id = var.container_app_environment_id
  resource_group_name          = var.resource_group_name
  revision_mode                = "Single"
  tags                         = var.tags

  identity {
    type         = "UserAssigned"
    identity_ids = [var.identity_id]
  }

  registry {
    server   = var.acr_login_server
    identity = var.identity_id
  }

  template {
    container {
      name   = each.key
      image  = "${var.acr_login_server}/${each.key}:latest"
      cpu    = 0.5
      memory = "1.0Gi"

      env {
        name  = "ASPNETCORE_ENVIRONMENT"
        value = "Production"
      }

      dynamic "env" {
        for_each = lookup(each.value, "db_name", null) != null ? [1] : []
        content {
          name = "DB_CONNECTION_STRING"
          value = format(
            "Server=%s;Database=%s;User ID=%s;Password=%s;",
            var.db_hostname,
            lookup(each.value, "db_name", ""),
            var.db_admin_username,
            var.db_admin_password
          )
        }
      }

      dynamic "env" {
        for_each = contains(["trip-service", "notification-service"], each.key) ? [1] : []
        content {
          name  = "KAFKA_BOOTSTRAP_SERVERS"
          value = var.kafka_bootstrap_server
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
          value = var.kafka_connection_string
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
        for_each = contains(["trip-service", "driver-service"], each.key) ? [1] : []
        content {
          name  = "REDIS_HOST"
          value = var.redis_hostname
        }
      }

      dynamic "env" {
        for_each = contains(["trip-service", "driver-service"], each.key) ? [1] : []
        content {
          name  = "REDIS_PORT"
          value = tostring(var.redis_port)
        }
      }

      dynamic "env" {
        for_each = contains(["trip-service", "driver-service"], each.key) ? [1] : []
        content {
          name  = "REDIS_PASSWORD"
          value = var.redis_password
        }
      }
    }
  }

  ingress {
    external_enabled = lookup(each.value, "external", false)
    target_port      = lookup(each.value, "port", 80)
    transport        = "auto"

    traffic_weight {
      percentage      = 100
      latest_revision = true
    }
  }

  depends_on = []
}
