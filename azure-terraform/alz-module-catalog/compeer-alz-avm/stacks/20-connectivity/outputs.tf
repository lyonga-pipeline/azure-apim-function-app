output "hub_vnet_id" { value = module.hub_vnet.resource_id }
output "hub_subnets" { value = module.hub_vnet.subnets }
output "connectivity_resource_group_name" { value = module.rg.name }
output "spoke_default_route_table_id" { value = module.spoke_default_route.resource_id }
output "hub_route_table_ids" { value = { for key, route_table in module.hub_route_table : key => route_table.resource_id } }
output "firewall_egress_public_ip_ids" { value = { for key, pip in module.firewall_egress_pip : key => pip.resource_id } }
output "palo_trust_ilb_id" { value = module.palo_trust_ilb.resource_id }
output "palo_untrust_ilb_id" { value = module.palo_untrust_ilb.resource_id }
output "expressroute_gateway_id" { value = module.expressroute_gateway.resource_id }
