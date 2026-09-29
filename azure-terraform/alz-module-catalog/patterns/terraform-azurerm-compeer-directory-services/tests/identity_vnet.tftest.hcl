mock_provider "azurerm" {}

# Exercises the 23 Sep 2026 placement decision: domain controllers move off
# the hub VNet into a dedicated identity VNet, peered to the hub, with their
# own recovery-services vault - instead of the legacy caller-supplied
# subnet_id (still covered by controller_contract.tftest.hcl's fixture).

variables {
  subscription_id = "00000000-0000-0000-0000-000000000000"
  location        = "centralus"
  environment     = "prod"
  resource_group  = { name = "rg-identity" }

  identity_vnet = {
    name          = "platform-cus-prod-identity-vnet"
    address_space = ["10.103.0.0/24"]
    subnets = {
      dc-subnet    = { address_prefixes = ["10.103.0.0/26"], nsg_key = "dc", route_table_key = "to_firewall" }
      extdc-subnet = { address_prefixes = ["10.103.0.64/26"], nsg_key = "dc", route_table_key = "to_firewall" }
    }
  }

  hub_connection = {
    hub_virtual_network_id = "/subscriptions/x/resourceGroups/rg-hub/providers/Microsoft.Network/virtualNetworks/hub-vnet"
  }

  network_security_groups = {
    dc = { name = "cus-prod-dc-nsg" }
  }

  route_tables = {
    to_firewall = { name = "cus-prod-to-firewall-rt" }
  }

  recovery_services_vaults = {
    identity = { name = "platform-cus-prod-identity-rsv" }
  }

  domain_controllers = {
    dc01 = {
      name                = "platform-cus-prod-dc-01"
      nic_name            = "nic-dc01"
      subnet_key          = "dc-subnet"
      private_ip_address  = "10.103.0.4"
    }
    extdc01 = {
      name                = "platform-cus-prod-extdc-01"
      nic_name            = "nic-extdc01"
      subnet_key          = "extdc-subnet"
      private_ip_address  = "10.103.0.68"
    }
  }

  admin_passwords = {
    dc01    = "NotAR3al!Secret#2026"
    extdc01 = "NotAR3al!Secret#2026"
  }

  dc_backup = {
    default_backup_policy_id = "/subscriptions/x/resourceGroups/rg-identity/providers/Microsoft.RecoveryServices/vaults/platform-cus-prod-identity-rsv/backupPolicies/default"
    protected_controllers = {
      dc01    = {}
      extdc01 = {}
    }
  }
}

run "identity_vnet_and_subnets_created" {
  command = plan

  assert {
    condition     = module.identity_vnet[0].name == "platform-cus-prod-identity-vnet"
    error_message = "identity VNet should be created with the caller-supplied name"
  }
  assert {
    condition     = length(module.identity_vnet[0].subnet_ids) == 2
    error_message = "both identity-VNet subnets should be created"
  }
}

run "hub_peering_created" {
  command = plan

  assert {
    condition     = length(module.identity_vnet_to_hub_peering) == 1
    error_message = "identity VNet should peer to the hub when hub_connection is set"
  }
}

run "nsg_and_route_table_associations_created" {
  command = plan

  assert {
    condition     = length(module.subnet_nsg_associations) == 2
    error_message = "both subnets should associate to the dc NSG via the inline nsg_key hint"
  }
  assert {
    condition     = length(module.subnet_route_table_associations) == 2
    error_message = "both subnets should associate to the to_firewall route table via the inline route_table_key hint"
  }
}

run "identity_rsv_created_and_dc_backup_defaults_to_it" {
  command = plan

  assert {
    condition     = module.recovery_services_vaults["identity"].name == "platform-cus-prod-identity-rsv"
    error_message = "the identity recovery-services vault should be created directly by this pattern"
  }
  assert {
    condition     = alltrue([for k, v in azurerm_backup_protected_vm.dc : v.recovery_vault_name == "platform-cus-prod-identity-rsv"])
    error_message = "dc_backup should default recovery_vault_name to the locally-created identity vault when vault_name isn't set explicitly"
  }
}
