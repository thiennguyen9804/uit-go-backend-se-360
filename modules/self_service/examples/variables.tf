variable "resource_group_name" {
  type    = string
  default = "rg-self-service-example"
}

variable "location" {
  type    = string
  default = "eastus"
}

variable "container_group_name" {
  type    = string
  default = "example-cg"
}

variable "container_name" {
  type    = string
  default = "example-container"
}

variable "dns_name_label" {
  type    = string
  default = "example-svc"
}

variable "image" {
  type    = string
  default = ""
}

variable "ports" {
  type    = list(number)
  default = [80]
}

variable "cpu" {
  type    = number
  default = 0.5
}

variable "memory" {
  type    = number
  default = 1
}

variable "environment_variables" {
  type    = map(string)
  default = {}
}

variable "tags" {
  type    = map(string)
  default = {}
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
}

variable "kafka_bootstrap_server" {
  type    = string
  default = ""
}

variable "kafka_connection_string" {
  type    = string
  default = ""
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
}
