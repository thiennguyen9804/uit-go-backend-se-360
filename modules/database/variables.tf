variable "resource_group_name" {
  description = "Resource group for database resources."
  type        = string
}

variable "location" {
  description = "Region for database resources."
  type        = string
}

variable "db_admin_username" {
  description = "DB admin username."
  type        = string
}

variable "db_admin_password" {
  description = "DB admin password."
  type        = string
  sensitive   = true
}

variable "service_databases" {
  description = "List of database names to create for services."
  type        = list(string)
  default     = []
}

variable "db_subnet_id" {
  description = "Subnet ID for private endpoint."
  type        = string
}

variable "tags" {
  description = "Tags for database resources."
  type        = map(string)
  default     = {}
}
