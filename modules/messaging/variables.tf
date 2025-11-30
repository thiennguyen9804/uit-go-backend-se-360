variable "resource_group_name" {
  description = "Resource group for messaging resources."
  type        = string
}

variable "location" {
  description = "Region for messaging resources."
  type        = string
}

variable "tags" {
  description = "Tags for messaging resources."
  type        = map(string)
  default     = {}
}
