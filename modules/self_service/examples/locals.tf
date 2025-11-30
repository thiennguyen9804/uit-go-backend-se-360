locals {
  # If examples create the network, use the created subnet id, otherwise use provided aca_subnet_id
  aca_subnet_id_final = var.create_network && length(module.network) > 0 ? module.network[0].aca_subnet_id : var.aca_subnet_id
}
