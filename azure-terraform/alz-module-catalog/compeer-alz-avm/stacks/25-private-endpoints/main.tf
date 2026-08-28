# NET-29: generic private-endpoint contract for PaaS resources that do not use
# the private_endpoints interface embedded in their AVM resource module.
module "private_endpoint" {
  for_each = var.endpoints
  source   = "app.terraform.io/Compeer-Financial-Services/compeer-private-endpoint/azurerm"
  version  = "1.0.5"

  name                          = each.value.name
  custom_network_interface_name = each.value.network_interface_name
  location                      = var.location
  resource_group_name           = each.value.resource_group_name
  subnet_id                     = each.value.subnet_resource_id
  private_service_connections = [
    {
      name                           = "${each.value.name}-psc"
      is_manual_connection           = false
      private_connection_resource_id = each.value.private_connection_resource_id
      subresource_names              = each.value.subresource_names
    }
  ]
  private_dns_zone_group = length(each.value.private_dns_zone_resource_ids) == 0 ? [] : [
    {
      name                 = "default"
      private_dns_zone_ids = each.value.private_dns_zone_resource_ids
    }
  ]
  ip_configurations = each.value.private_ip_address == null ? [] : [
    {
      name               = "primary"
      private_ip_address = each.value.private_ip_address
      subresource_name   = each.value.subresource_names[0]
      member_name        = each.value.subresource_names[0]
    }
  ]
  tags = merge({ ManagedBy = "Terraform", IaCSource = "CompeerHCP" }, each.value.tags)
}
