locals {
  sanitized_rg_name = lower(replace(var.resource_group_name, "-", ""))
}

# Azure Event Hubs namespace with Kafka protocol enabled
resource "azurerm_eventhub_namespace" "kafka" {
  name                = "evh-${local.sanitized_rg_name}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  sku                      = "Standard"
  capacity                 = 1
  auto_inflate_enabled     = true
  maximum_throughput_units = 4
}

resource "azurerm_eventhub" "kafka" {
  name                = "kafka-hub"
  namespace_name      = azurerm_eventhub_namespace.kafka.name
  resource_group_name = azurerm_resource_group.main.name

  partition_count   = 2
  message_retention = 1
}

resource "azurerm_eventhub_authorization_rule" "kafka_send_listen" {
  name                = "hub-shared-access"
  namespace_name      = azurerm_eventhub_namespace.kafka.name
  eventhub_name       = azurerm_eventhub.kafka.name
  resource_group_name = azurerm_resource_group.main.name

  listen = true
  send   = true
  manage = false
}

# Azure Cache for Redis instance
resource "azurerm_redis_cache" "main" {
  name                = "redis${local.sanitized_rg_name}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  capacity = 1
  family   = "C"
  sku_name = "Basic"

  enable_non_ssl_port           = true
  minimum_tls_version           = "1.2"
  public_network_access_enabled = true
}

