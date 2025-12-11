locals {
  # If examples create the network, use the created subnet id, otherwise use provided aca_subnet_id
  # Using try() to avoid circular dependency when module.network doesn't exist yet
  aca_subnet_id_final = var.create_network ? try(module.network[0].aca_subnet_id, var.aca_subnet_id) : var.aca_subnet_id
}
