locals {
	sanitized_rg_name = lower(replace(var.resource_group_name, "-", ""))
}

resource "azurerm_eventhub_namespace" "kafka" {
	name                = "evh-${local.sanitized_rg_name}"
	location            = var.location
	resource_group_name = var.resource_group_name

	sku                      = "Standard"
	capacity                 = 1
	auto_inflate_enabled     = true
	maximum_throughput_units = 4
	tags                     = var.tags
}

resource "azurerm_eventhub" "kafka" {
	name                = "kafka-hub"
	namespace_name      = azurerm_eventhub_namespace.kafka.name
	resource_group_name = var.resource_group_name

	partition_count   = 2
	message_retention = 1
}

resource "azurerm_eventhub_authorization_rule" "kafka_send_listen" {
	name                = "hub-shared-access"
	namespace_name      = azurerm_eventhub_namespace.kafka.name
	eventhub_name       = azurerm_eventhub.kafka.name
	resource_group_name = var.resource_group_name

	listen = true
	send   = true
	manage = false
}

resource "azurerm_redis_cache" "main" {
	name                = "redis${local.sanitized_rg_name}"
	location            = var.location
	resource_group_name = var.resource_group_name

	capacity = 1
	family   = "C"
	sku_name = "Basic"

	enable_non_ssl_port           = true
	minimum_tls_version           = "1.2"
	public_network_access_enabled = true
	tags                          = var.tags
}

output "eventhub_namespace_name" {
	value = azurerm_eventhub_namespace.kafka.name
}

output "eventhub_authorization_connection_string" {
	value = azurerm_eventhub_authorization_rule.kafka_send_listen.primary_connection_string
}

output "redis_hostname" {
	value = azurerm_redis_cache.main.hostname
}

output "redis_port" {
	value = azurerm_redis_cache.main.port
}

output "redis_id" {
	value = azurerm_redis_cache.main.id
}
