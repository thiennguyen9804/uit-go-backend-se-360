locals {
  required_tags = ["Service", "Owner", "Environment", "CostCenter", "Project"]
}

resource "azurerm_resource_group" "demo" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.standard_tags
}

# Enforce standard tags on all resources within the resource group.
resource "azurerm_policy_definition" "require_tags" {
  name         = "require-standard-cost-tags"
  display_name = "Require standard cost allocation tags"
  policy_type  = "Custom"
  mode         = "Indexed"
  description  = "Deny creation/update of resources without required cost allocation tags."

  policy_rule = jsonencode({
    if = {
      anyOf = [
        for tag in local.required_tags : {
          field  = "[concat('tags[', '${tag}', ']')]"
          exists = "false"
        }
      ]
    }
    then = {
      effect = "deny"
    }
  })
}

resource "azurerm_policy_assignment" "require_tags" {
  name                 = "enforce-standard-cost-tags"
  display_name         = "Enforce standard cost allocation tags"
  scope                = azurerm_resource_group.demo.id
  policy_definition_id = azurerm_policy_definition.require_tags.id
  description          = "Prevents resources in the RG from being created/updated without standard tags."
}

# Monthly budget scoped to the demo resource group with 50/80/100% alerts.
resource "azurerm_consumption_budget_resource_group" "monthly" {
  name              = "rg-demo-cost-budget"
  resource_group_id = azurerm_resource_group.demo.id
  amount            = var.budget_amount
  time_grain        = "Monthly"

  time_period {
    start_date = var.budget_start_date
    end_date   = var.budget_end_date
  }

  notification {
    enabled        = true
    threshold      = 50
    operator       = "GreaterThan"
    threshold_type = "Actual"
    contact_emails = var.budget_contact_emails
  }

  notification {
    enabled        = true
    threshold      = 80
    operator       = "GreaterThan"
    threshold_type = "Actual"
    contact_emails = var.budget_contact_emails
  }

  notification {
    enabled        = true
    threshold      = 100
    operator       = "GreaterThan"
    threshold_type = "Actual"
    contact_emails = var.budget_contact_emails
  }
}

output "resource_group_name" {
  description = "Resource group for the cost demo."
  value       = azurerm_resource_group.demo.name
}

output "budget_id" {
  description = "ID of the monthly budget."
  value       = azurerm_consumption_budget_resource_group.monthly.id
}

