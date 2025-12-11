locals {
  required_tags         = ["Service", "Owner", "Environment", "CostCenter", "Project"]
  current_month         = formatdate("2006-01", timestamp())
  next_month            = formatdate("2006-01", timeadd(timestamp(), "720h"))
  default_budget_start  = "${local.current_month}-01T00:00:00Z"
  default_budget_end    = "${local.next_month}-01T00:00:00Z"
  budget_start_resolved = coalesce(var.budget_start_date, local.default_budget_start)
  budget_end_resolved   = coalesce(var.budget_end_date, local.default_budget_end)
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

resource "azurerm_resource_group_policy_assignment" "require_tags" {
  name                 = "enforce-standard-cost-tags"
  display_name         = "Enforce standard cost allocation tags"
  resource_group_id    = azurerm_resource_group.demo.id
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
    start_date = local.budget_start_resolved
    end_date   = local.budget_end_resolved
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

  notification {
    enabled        = true
    threshold      = 1
    operator       = "GreaterThan"
    threshold_type = "Forecasted"
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

