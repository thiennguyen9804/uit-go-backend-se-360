variable "resource_group_name" {
  description = "Resource group for networking resources."
  type        = string
}

variable "location" {
  description = "Region for networking resources."
  type        = string
}

variable "vnet_address_space" {
  description = "VNet address space." 
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "aca_subnet_address_space" {
  description = "ACA subnet address prefixes." 
  type        = list(string)
  default     = ["10.0.1.0/24"]
}

variable "db_subnet_address_space" {
  description = "DB subnet address prefixes." 
  type        = list(string)
  default     = ["10.0.2.0/24"]
}

variable "tags" {
  description = "Tags applied to networking resources."
  type        = map(string)
  default     = {}
}
variable "container_app_environment_id" {
  description = "Container Apps Environment ID to create dependency for proper destroy order. Subnet will be destroyed after this resource."
  type        = string
  default     = null
}