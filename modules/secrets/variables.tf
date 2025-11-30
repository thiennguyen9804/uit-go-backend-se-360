variable "resource_group_name" {
  description = "Resource group for secrets (Key Vault)."
  type        = string
}

variable "location" {
  description = "Region for Key Vault."
  type        = string
}

variable "tenant_id" {
  description = "Tenant ID for Key Vault." 
  type        = string
  default     = ""
}

variable "db_admin_password" {
  description = "DB admin password to store in Key Vault."
  type        = string
  sensitive   = true
}

variable "tags" {
  description = "Tags for Key Vault."
  type        = map(string)
  default     = {}
}

variable "aca_identity_principal_id" {
  description = "Principal id of the ACA user assigned identity which will access Key Vault."
  type        = string
}

variable "acr_id" {
  description = "Resource id of ACR used for role assignment."
  type        = string
}
