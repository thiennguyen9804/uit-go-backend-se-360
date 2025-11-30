variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "create_network" {
  type    = bool
  default = false
}

variable "vnet_address_space" {
  type    = list(string)
  default = ["10.0.0.0/16"]
}

variable "aca_subnet_address_space" {
  type    = list(string)
  default = ["10.0.1.0/24"]
}

variable "db_subnet_address_space" {
  type    = list(string)
  default = ["10.0.2.0/24"]
}

variable "aca_subnet_id" {
  type    = string
  default = ""
}

variable "service_key" {
  type    = string
  default = "driver-service"
}

variable "service_port" {
  type    = number
  default = 80
}

variable "external" {
  type    = bool
  default = true
}

variable "deploy_service" {
  type    = bool
  default = true
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "db_hostname" {
  type        = string
  default     = ""
  description = "Database hostname"
}

variable "db_admin_username" {
  type        = string
  default     = ""
  description = "Database admin username"
}

variable "db_admin_password" {
  type        = string
  default     = ""
  description = "Database admin password"
}

variable "kafka_bootstrap_server" {
  type        = string
  default     = ""
  description = "Kafka bootstrap server"
}

variable "kafka_connection_string" {
  type        = string
  default     = ""
  description = "Kafka connection string"
}

variable "redis_hostname" {
  type        = string
  default     = ""
  description = "Redis hostname"
}

variable "redis_port" {
  type        = number
  default     = 0
  description = "Redis port"
}

variable "redis_password" {
  type        = string
  default     = ""
  description = "Redis password"
}
