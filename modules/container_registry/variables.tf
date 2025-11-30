variable "resource_group_name" {
  description = "Resource group for ACR."
  type        = string
}

variable "location" {
  description = "Region for ACR."
  type        = string
}

variable "sku" {
  description = "ACR SKU" 
  type        = string
  default     = "Basic"
}

variable "tags" {
  description = "Tags to apply to ACR." 
  type        = map(string)
  default     = {}
}
