// Self-service Terraform module to deploy a container into Azure Container Instances (ACI)

variable "resource_group_name" {
  description = "Name of the resource group to create/use"
  type        = string
}

variable "location" {
  description = "Azure location"
  type        = string
  default     = "eastus"
}

variable "container_group_name" {
  description = "Name of the container group"
  type        = string
}

variable "container_name" {
  description = "Name of the container inside the group"
  type        = string
}

variable "image" {
  description = "Container image to deploy (including registry)"
  type        = string
}

variable "cpu" {
  description = "CPU cores for the container"
  type        = number
  default     = 0.5
}

variable "memory" {
  description = "Memory (GB) for the container"
  type        = number
  default     = 1
}

variable "ports" {
  description = "List of ports to expose"
  type        = list(number)
  default     = [80]
}

variable "os_type" {
  description = "OS type for ACI: Linux or Windows"
  type        = string
  default     = "Linux"
}

variable "dns_name_label" {
  description = "DNS name label for the container group IP (unique within region)"
  type        = string
  default     = ""
}

variable "environment_variables" {
  description = "Map of environment variables for the container"
  type        = map(string)
  default     = {}
}

variable "tags" {
  description = "Tags to apply"
  type        = map(string)
  default     = {}
}

resource "azurerm_resource_group" "this" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_container_group" "this" {
  name                = var.container_group_name
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  os_type             = var.os_type

  dynamic "container" {
    for_each = [1]
    content {
      name  = var.container_name
      image = var.image
      cpu   = var.cpu
      memory = var.memory

      dynamic "ports" {
        for_each = var.ports
        content {
          port = ports.value
        }
      }

      environment_variables = var.environment_variables
    }
  }

  ip_address_type = "public"

  dynamic "port" {
    for_each = var.ports
    content {
      port     = port.value
      protocol = "TCP"
    }
  }

  dns_name_label = var.dns_name_label == "" ? null : var.dns_name_label
  tags           = var.tags
}
