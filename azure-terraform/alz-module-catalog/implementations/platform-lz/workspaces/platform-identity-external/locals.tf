# PHASE2 NEW: mirror the unchanged directory pattern's inline/explicit association resolution.
locals {
  nsg_associations = merge(var.identity_vnet == null ? {} : {
    for key, subnet in var.identity_vnet.subnets : key => { subnet_key = key, nsg_key = subnet.nsg_key } if subnet.nsg_key != null
  }, var.subnet_nsg_associations)
  route_associations = merge(var.identity_vnet == null ? {} : {
    for key, subnet in var.identity_vnet.subnets : key => { subnet_key = key, route_table_key = subnet.route_table_key } if subnet.route_table_key != null
  }, var.subnet_route_table_associations)
}
