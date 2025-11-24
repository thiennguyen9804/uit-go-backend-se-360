# Variables for resource naming and location
variable "resource_group_name" {
  description = "Name for the Azure Resource Group."
  type        = string
  default     = "rg-microservice-vn"
}

variable "location" {
  description = "Azure region to deploy resources."
  type        = string
  default     = "East Asia"
}

# Networking variables
variable "vnet_address_space" {
  description = "The address space for the VNet."
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "aca_subnet_address_space" {
  description = "The address space for the Container Apps subnet."
  type        = list(string)
  default     = ["10.0.1.0/24"]
}

variable "db_subnet_address_space" {
  description = "The address space for the Database Private Endpoint Subnet."
  type        = list(string)
  default     = ["10.0.2.0/24"]
}

# Database variables
variable "db_admin_username" {
  description = "Administrator username for Azure SQL."
  type        = string
  default     = "tfadmin"
}

variable "db_admin_password" {
  description = "Administrator password for Azure SQL."
  type        = string
  default     = "YourStrong@Passw0rd"
}