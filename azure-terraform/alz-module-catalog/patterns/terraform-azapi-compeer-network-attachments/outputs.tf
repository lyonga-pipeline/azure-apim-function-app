output "contract_version" {
  description = "Attachment batch consumer contract, independent of the module release version."
  value       = "1.0.0"
}

output "attachments" {
  description = "Managed child IDs and observed peering states. A successful apply is not end-to-end network acceptance."
  value = { for key, attachment in var.attachments : key => {
    attachment_kind          = attachment.attachment_kind
    environment              = local.attachment_environments[key]
    hub_virtual_network_id   = var.hub.virtual_network_id
    spoke_virtual_network_id = attachment.spoke_virtual_network_id
    hub_to_spoke_id          = azapi_resource.hub_to_spoke[key].id
    spoke_to_hub_id          = azapi_resource.spoke_to_hub[key].id
    peering_names            = local.peering_names[key]
    hub_peering_state        = try(azapi_resource.hub_to_spoke[key].output.properties.peeringState, null)
    spoke_peering_state      = try(azapi_resource.spoke_to_hub[key].output.properties.peeringState, null)
    private_dns_link_ids     = { for link_key, link in azapi_resource.dns_link : link_key => link.id if local.dns_links[link_key].attachment_key == key }
  } }
  depends_on = [terraform_data.inventory_contract, terraform_data.producer_contract, terraform_data.ipam_contract]
}
