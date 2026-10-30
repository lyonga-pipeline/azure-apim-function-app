variables {
  vnet_peerings          = { forward = { local_vnet = "SHARED-HUB-VNET", remote_vnet = "PLATFORM-SERVICES-VNET" } }
  private_dns_link_vnets = ["PLATFORM-SERVICES-VNET"]
}
run "parent_naming_reference" {
  command = plan
  # Monorepo-only reference: parity with the published naming module's formulas.
  module { source = "../../../../modules/terraform-azurerm-compeer-naming" }
  variables {
    region      = "centralus"
    environment = "prod"
    scope       = "platform"
    component   = "connectivity"
  }
}
run "name_only_helper_preserves_canonical_outputs_without_environment_inputs" {
  command = plan
  assert {
    condition     = output.vnet_peering_names == run.parent_naming_reference.vnet_peering_names && output.private_dns_link_names == run.parent_naming_reference.private_dns_link_names
    error_message = "Generic attachment names must remain identical to the established canonical naming convention."
  }
}
run "overlong_names_are_not_silently_changed" {
  command = plan
  variables {
    vnet_peerings = { forward = { local_vnet = "a-very-long-but-existing-virtual-network-name", remote_vnet = "another-very-long-but-existing-virtual-network-name" } }
  }
  expect_failures = [output.vnet_peering_names]
}
