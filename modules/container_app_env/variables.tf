variable "resource_group_name" {
  description = "Resource group for container app environment."
  type        = string
}

variable "location" {
  description = "Region for the container app environment."
  type        = string
}

variable "aca_subnet_id" {
  description = "Subnet id to place the ACA infra in (required)."
  type        = string
}

variable "tags" {
  description = "Tags for the ACA environment."
  type        = map(string)
  default     = {}
}
