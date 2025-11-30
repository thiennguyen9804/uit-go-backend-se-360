variable "services" {
  description = "Map of services to deploy. Each value should include at least `port` and optional `db_name` and `external` flag." 
  type        = map(any)
}

variable "container_app_environment_id" {
  description = "ACA Environment ID where the container apps will be created."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group name to create container apps in."
  type        = string
}

variable "identity_id" {
  description = "User Assigned Identity ID for the container apps."
  type        = string
}

variable "acr_login_server" {
  description = "ACR login server used to resolve container images."
  type        = string
}

variable "db_hostname" {
  description = "Database server hostname (FQDN) used in DB connection strings."
  type        = string
}

variable "db_admin_username" {
  description = "DB admin username used for connection strings."
  type        = string
}

variable "db_admin_password" {
  description = "DB admin password (sensitive)."
  type        = string
  sensitive   = true
}

variable "kafka_bootstrap_server" {
  description = "Kafka bootstrap server (Event Hubs with Kafka)."
  type        = string
  default     = ""
}

variable "kafka_connection_string" {
  description = "Primary connection string for Kafka/EventHub auth."
  type        = string
  default     = ""
}

variable "redis_hostname" {
  description = "Redis hostname."
  type        = string
  default     = ""
}

variable "redis_port" {
  description = "Redis port."
  type        = number
  default     = 0
}

variable "redis_password" {
  description = "Redis primary access key."
  type        = string
  default     = ""
}

variable "tags" {
  description = "Tags to apply to created resources."
  type        = map(string)
  default     = {}
}
