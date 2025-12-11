variable "resource_group_name" {
  type    = string
  default = "rg-self-service-example"
}

variable "location" {
  description = "Azure region for all resources."
  type        = string
  default     = "eastasia"
}

variable "aca_subnet_id" {
  description = "Subnet id to use for Container Apps environment (required)."
  type        = string
  default     = ""
}

variable "create_network" {
  description = "If true, examples will create a new VNet + subnets using the modules/network module and set aca_subnet_id automatically."
  type        = bool
  default     = false
}

variable "deploy_service" {
  description = "If true, deploy the service container app. If false, only create infrastructure (ACR, ACA env, network)."
  type        = bool
  default     = true
}

variable "vnet_address_space" {
  description = "VNet address space used when creating network"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "aca_subnet_address_space" {
  description = "ACA subnet address prefixes used when creating network"
  type        = list(string)
  default     = ["10.0.1.0/24"]
}

variable "db_subnet_address_space" {
  description = "DB subnet address prefixes used when creating network"
  type        = list(string)
  default     = ["10.0.2.0/24"]
}

variable "service_key" {
  description = "Service name/key to deploy (this will be used as the image name tag)."
  type        = string
  default     = "example-service"
}

variable "service_port" {
  description = "Port the service listens on"
  type        = number
  default     = 80
}

variable "external" {
  description = "Whether the container app should be externally reachable"
  type        = bool
  default     = true
}

variable "image" {
  description = "Full image URL (e.g., acr.azurecr.io/service:latest)"
  type        = string
  default     = ""
}

variable "cpu" {
  description = "CPU cores for the container (0.25, 0.5, 1.0, etc.)"
  type        = number
  default     = 0.5
}

variable "memory" {
  description = "Memory for the container (e.g., 0.5Gi, 1.0Gi)"
  type        = string
  default     = "1.0Gi"
}

variable "min_replicas" {
  description = "Minimum number of replicas (0 for scale-to-zero)"
  type        = number
  default     = 0
}

variable "max_replicas" {
  description = "Maximum number of replicas"
  type        = number
  default     = 3
}

variable "db_hostname" {
  type    = string
  default = ""
}

variable "db_admin_username" {
  type    = string
  default = ""
}

variable "db_admin_password" {
  type    = string
  default = ""
  sensitive = true
}

variable "kafka_bootstrap_server" {
  type    = string
  default = ""
}

variable "kafka_connection_string" {
  type    = string
  default = ""
  sensitive = true
}

variable "redis_hostname" {
  type    = string
  default = ""
}

variable "redis_port" {
  type    = number
  default = 0
}

variable "redis_password" {
  type    = string
  default = ""
  sensitive = true
}

variable "tags" {
  type    = map(string)
  default = {}
}
