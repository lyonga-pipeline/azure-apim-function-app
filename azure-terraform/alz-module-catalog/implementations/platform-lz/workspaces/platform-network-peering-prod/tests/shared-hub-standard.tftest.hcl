mock_provider "azapi" {}
mock_provider "tfe" {}

# Exercise the committed root tfvars without contacting Azure or any producer.
run "committed_spoke_inventory_enables_gateway_route_server_transit" {
  command = plan
  variables { enabled = false }
  assert {
    condition = var.hub.gateway_ready && length(var.attachments) > 0 && alltrue([
      for attachment in values(var.attachments) : attachment.gateway_transit && attachment.allow_forwarded_traffic
    ])
    error_message = "Compeer spoke inventories must explicitly enable paired hub gateway/Route Server transit and forwarding."
  }
}
