# Real producer and consumer roots; only Azure/HCP responses are mocked.
mock_provider "azurerm" {
  mock_data "azurerm_client_config" {
    defaults = { subscription_id = "11111111-1111-1111-1111-111111111111", tenant_id = "cccccccc-cccc-cccc-cccc-cccccccccccc" }
  }
  mock_resource "azurerm_virtual_network" {
    defaults = { id = "/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/identity-cus-prod-ext-dc-rg/providers/Microsoft.Network/virtualNetworks/identity-cus-prod-ext-dc-vnet" }
  }
  mock_resource "azurerm_subnet" {
    defaults = { id = "/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/identity-cus-prod-ext-dc-rg/providers/Microsoft.Network/virtualNetworks/identity-cus-prod-ext-dc-vnet/subnets/external-dc-subnet" }
  }
  mock_resource "azurerm_network_security_group" {
    defaults = { id = "/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/identity-cus-prod-ext-dc-rg/providers/Microsoft.Network/networkSecurityGroups/identity-cus-prod-ext-dc-nsg" }
  }
  mock_resource "azurerm_route_table" {
    defaults = { id = "/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/identity-cus-prod-ext-dc-rg/providers/Microsoft.Network/routeTables/identity-cus-prod-ext-dc-rt" }
  }
  mock_resource "azurerm_network_interface" {
    defaults = { id = "/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/identity-cus-prod-ext-dc-rg/providers/Microsoft.Network/networkInterfaces/mock-dc-nic" }
  }
  mock_resource "azurerm_windows_virtual_machine" {
    defaults = { id = "/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/identity-cus-prod-ext-dc-rg/providers/Microsoft.Compute/virtualMachines/mock-dc" }
  }
  mock_resource "azurerm_managed_disk" {
    defaults = { id = "/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/identity-cus-prod-ext-dc-rg/providers/Microsoft.Compute/disks/mock-adds" }
  }
  mock_resource "azurerm_backup_policy_vm" {
    defaults = { id = "/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/identity-cus-prod-ext-dc-rg/providers/Microsoft.RecoveryServices/vaults/platform-cus-prod-identity-ext-rsv/backupPolicies/tier0" }
  }
}
mock_provider "azapi" {
  mock_data "azapi_client_config" {
    defaults = { tenant_id = "cccccccc-cccc-cccc-cccc-cccccccccccc" }
  }
  mock_resource "azapi_resource" {
    defaults = { output = { properties = { peeringState = "Connected", provisioningState = "Succeeded" } } }
  }
}
mock_provider "tfe" {}

run "external_identity_publishes_actual_v3_contract" {
  command = apply
  variables {
    enabled                         = true
    existing_identity_owner_checked = true
    deployment_approved             = true
    admin_passwords                 = { dc01 = "MockOnly!2026-Not-A-Real-Secret", dc02 = "MockOnly!2026-Not-A-Real-Secret" }
  }
  assert {
    condition = (
      output.network_attachment_contract.contract_version == "3.0.0" &&
      output.network_attachment_contract.context.attachment_kind == "platform" &&
      output.network_attachment_contract.context.environment == "prod" &&
      output.network_attachment_contract.spoke_virtual_network_id == module.external_identity[0].identity_vnet_id &&
      toset(output.network_attachment_contract.address_space) == toset(module.external_identity[0].identity_vnet_address_space) &&
      output.network_attachment_contract.spoke_virtual_network_id == output.central_attachment_inputs.spoke_virtual_network_id &&
      !output.network_attachment_contract.gateway_transit_enabled &&
      length(module.external_identity[0].identity_vnet_subnet_ids) == 1
    )
    error_message = "External identity must publish the real VNet metadata as a platform-v3 contract without replacing its legacy output or owning peering."
  }
}

run "prod_attachment_root_consumes_actual_external_identity_output" {
  command = apply
  module { source = "../platform-network-peering-prod" }
  variables {
    enabled                   = true
    tenant_id                 = "cccccccc-cccc-cccc-cccc-cccccccccccc"
    execution_subscription_id = "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa"
    allow_local_cli_auth      = true
    deployment_controls       = { approval_reference = "NET-MOCK-123", exclusive_ownership_verified = true, shared_hub_gate_configured = true }
    hub = {
      virtual_network_id = "/subscriptions/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa/resourceGroups/hub/providers/Microsoft.Network/virtualNetworks/shared-hub-vnet"
      address_space      = ["10.102.0.0/21"]
      organization       = "Compeer-Financial-Services"
      workspace          = "platform-connectivity"
    }
    # Approved inventory stays independent of producer outputs; HCP reads cross-check it.
    attachments = { external_identity_prod = {
      attachment_kind          = "platform"
      environment              = "prod"
      spoke_virtual_network_id = "/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/identity-cus-prod-ext-dc-rg/providers/Microsoft.Network/virtualNetworks/identity-cus-prod-ext-dc-vnet"
      address_space            = ["10.210.0.0/24"]
      producer                 = { organization = "Compeer-Financial-Services", workspace = "platform-identity-external", contract_version = "3.0.0" }
      approval_reference       = "NET-MOCK-123"
      ipam_reference           = "IPAM-MOCK-123"
      gateway_transit          = false
      allow_forwarded_traffic  = true
      peering_names = {
        hub_to_spoke = "peer-hub-to-identity-cus-prod-ext-dc-vnet"
        spoke_to_hub = "peer-identity-cus-prod-ext-dc-vnet-to-hub"
      }
    } }
  }
  override_data {
    target = module.attachments[0].data.tfe_outputs.hub[0]
    values = { nonsensitive_values = {
      contract_version                  = "0.1.0"
      hub_virtual_network_id            = "/subscriptions/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa/resourceGroups/hub/providers/Microsoft.Network/virtualNetworks/shared-hub-vnet"
      hub_virtual_network_address_space = ["10.102.0.0/21"]
    } }
  }
  override_data {
    target = module.attachments[0].data.tfe_outputs.spoke["external_identity_prod"]
    # Terraform 1.11 requires literal overrides. Assert exact parity with the real producer below.
    values = { nonsensitive_values = { network_attachment_contract = {
      contract_version                 = "3.0.0"
      owner                            = "central-attachment-workspace"
      hub_virtual_network_id           = "/subscriptions/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa/resourceGroups/hub/providers/Microsoft.Network/virtualNetworks/shared-hub-vnet"
      spoke_virtual_network_id         = "/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/identity-cus-prod-ext-dc-rg/providers/Microsoft.Network/virtualNetworks/identity-cus-prod-ext-dc-vnet"
      spoke_virtual_network_name       = "identity-cus-prod-ext-dc-vnet"
      spoke_resource_group_name        = "identity-cus-prod-ext-dc-rg"
      address_space                    = ["10.210.0.0/24"]
      gateway_transit_enabled          = false
      private_dns_zone_ids             = {}
      private_dns_registration_enabled = false
      context = {
        tenant_id       = "cccccccc-cccc-cccc-cccc-cccccccccccc"
        subscription_id = "11111111-1111-1111-1111-111111111111"
        environment     = "prod"
        attachment_kind = "platform"
      }
    } } }
  }
  override_data {
    target = module.attachments[0].data.azapi_resource.hub[0]
    values = { output = { properties = { addressSpace = { addressPrefixes = ["10.102.0.0/21"] } } } }
  }
  override_data {
    target = module.attachments[0].data.azapi_resource.spoke["external_identity_prod"]
    values = { output = { properties = { addressSpace = { addressPrefixes = ["10.210.0.0/24"] } } } }
  }
  assert {
    condition = (
      # Keep this expected wire payload identical to the literal HCP response above.
      jsonencode(run.external_identity_publishes_actual_v3_contract.network_attachment_contract) == jsonencode({
        contract_version                 = "3.0.0"
        owner                            = "central-attachment-workspace"
        hub_virtual_network_id           = "/subscriptions/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa/resourceGroups/hub/providers/Microsoft.Network/virtualNetworks/shared-hub-vnet"
        spoke_virtual_network_id         = "/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/identity-cus-prod-ext-dc-rg/providers/Microsoft.Network/virtualNetworks/identity-cus-prod-ext-dc-vnet"
        spoke_virtual_network_name       = "identity-cus-prod-ext-dc-vnet"
        spoke_resource_group_name        = "identity-cus-prod-ext-dc-rg"
        address_space                    = ["10.210.0.0/24"]
        gateway_transit_enabled          = false
        private_dns_zone_ids             = {}
        private_dns_registration_enabled = false
        context = {
          tenant_id       = "cccccccc-cccc-cccc-cccc-cccccccccccc"
          subscription_id = "11111111-1111-1111-1111-111111111111"
          environment     = "prod"
          attachment_kind = "platform"
        }
      })
    )
    error_message = "HCP mock payload must match the actual public identity producer contract: ${jsonencode(run.external_identity_publishes_actual_v3_contract.network_attachment_contract)}."
  }
  assert {
    condition = (
      length(output.attachments) == 1 &&
      output.attachments.external_identity_prod.spoke_virtual_network_id == run.external_identity_publishes_actual_v3_contract.network_attachment_contract.spoke_virtual_network_id &&
      output.attachments.external_identity_prod.attachment_kind == "platform" &&
      output.attachments.external_identity_prod.peering_names.hub_to_spoke == "peer-hub-to-identity-cus-prod-ext-dc-vnet" &&
      output.attachments.external_identity_prod.peering_names.spoke_to_hub == "peer-identity-cus-prod-ext-dc-vnet-to-hub" &&
      output.attachments.external_identity_prod.hub_to_spoke_id != null &&
      output.attachments.external_identity_prod.spoke_to_hub_id != null &&
      length(output.attachments.external_identity_prod.private_dns_link_ids) == 0
    )
    error_message = "The production attachment root must consume the actual identity owner output and own both named peerings without inventing DNS links."
  }
}

run "optional_private_dns_intent_is_metadata_only" {
  command = apply
  variables {
    enabled                         = true
    existing_identity_owner_checked = true
    deployment_approved             = true
    admin_passwords                 = { dc01 = "MockOnly!2026-Not-A-Real-Secret", dc02 = "MockOnly!2026-Not-A-Real-Secret" }
    central_attachment = {
      tenant_id              = "cccccccc-cccc-cccc-cccc-cccccccccccc"
      hub_virtual_network_id = "/subscriptions/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa/resourceGroups/hub/providers/Microsoft.Network/virtualNetworks/shared-hub-vnet"
      private_dns_zone_ids = {
        key_vault = "/subscriptions/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa/resourceGroups/dns/providers/Microsoft.Network/privateDnsZones/privatelink.vaultcore.azure.net"
      }
    }
  }
  assert {
    condition = (
      output.network_attachment_contract.private_dns_zone_ids == var.central_attachment.private_dns_zone_ids &&
      !output.network_attachment_contract.private_dns_registration_enabled &&
      output.network_attachment_contract.spoke_virtual_network_id == run.external_identity_publishes_actual_v3_contract.network_attachment_contract.spoke_virtual_network_id &&
      length(module.external_identity[0].domain_controller_ids) == 2
    )
    error_message = "Optional DNS intent must be published exactly without replacing the VNet/controllers or enabling DNS registration."
  }
}
