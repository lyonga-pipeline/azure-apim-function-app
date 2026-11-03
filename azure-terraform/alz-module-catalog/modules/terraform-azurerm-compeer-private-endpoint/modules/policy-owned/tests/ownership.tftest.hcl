mock_provider "azurerm" {}
variables {
  name                         = "orders-cus-prod-vault-pe"
  resource_group_name          = "security"
  location                     = "centralus"
  subnet_id                    = "/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/network/providers/Microsoft.Network/virtualNetworks/spoke/subnets/private-endpoints"
  policy_registration_approved = true
  private_service_connections = [{
    name                           = "vault"
    is_manual_connection           = false
    private_connection_resource_id = "/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/security/providers/Microsoft.KeyVault/vaults/orders-cus-prod-vault"
    subresource_names              = ["vault"]
  }]
}
run "endpoint_exists_without_terraform_dns_registration" {
  command = apply
  assert {
    condition     = output.id != null && length(azurerm_private_endpoint.private_endpoint.private_dns_zone_group) == 0 && output.subnet_id == var.subnet_id
    error_message = "The policy helper creates a private endpoint, never a DNS group."
  }
}
run "platform_approval_is_required" {
  command = plan
  variables { policy_registration_approved = false }
  expect_failures = [var.policy_registration_approved]
}
run "manual_connections_need_separate_verified_policy_coverage" {
  command = plan
  variables {
    private_service_connections = [{
      name                           = "vault"
      is_manual_connection           = true
      private_connection_resource_id = "/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/security/providers/Microsoft.KeyVault/vaults/orders-cus-prod-vault"
      subresource_names              = ["vault"]
    }]
  }
  expect_failures = [azurerm_private_endpoint.private_endpoint]
}
