variable "resource_group_name" {
  description = "Name of the dedicated resource group for cost demo."
  type        = string
  default     = "rg-demo-cost"
}

variable "location" {
  description = "Azure region for the resource group."
  type        = string
  default     = "eastasia"
}

variable "standard_tags" {
  description = "Standard cost-allocation tags applied to the resource group."
  type        = map(string)
  default = {
    Service     = "cost-demo"
    Owner       = "student"
    Environment = "demo"
    CostCenter  = "demo"
    Project     = "cost-visibility"
  }
}

variable "budget_amount" {
  description = "Monthly budget amount in USD."
  type        = number
  default     = 10
}

variable "budget_contact_emails" {
  description = "Emails to notify when thresholds are crossed."
  type        = list(string)
  default     = ["student@example.com"]
}

variable "budget_start_date" {
  description = "UTC start date for the budget (RFC3339). Defaults to first day of current month."
  type        = string
  default     = "2025-12-01T00:00:00Z"
}

variable "budget_end_date" {
  description = "UTC end date for the budget (RFC3339). Defaults to one year from start."
  type        = string
  default     = "2026-01-01T00:00:00Z"
}

