data "azurerm_client_config" "current" {}

data "terraform_remote_state" "connectivity" {
  backend = "azurerm"

  config = merge(
    {
      resource_group_name  = var.connectivity_state_rg
      storage_account_name = var.connectivity_state_sa
      container_name       = var.connectivity_state_container
      key                  = var.connectivity_state_key
      use_azuread_auth     = true
    },
    coalesce(var.connectivity_state_subscription_id, var.platform_state_subscription_id) == null ? {} : {
      subscription_id = coalesce(var.connectivity_state_subscription_id, var.platform_state_subscription_id)
    }
  )
}

data "terraform_remote_state" "management" {
  backend = "azurerm"

  config = merge(
    {
      resource_group_name  = var.management_state_rg
      storage_account_name = var.management_state_sa
      container_name       = var.management_state_container
      key                  = var.management_state_key
      use_azuread_auth     = true
    },
    coalesce(var.management_state_subscription_id, var.platform_state_subscription_id) == null ? {} : {
      subscription_id = coalesce(var.management_state_subscription_id, var.platform_state_subscription_id)
    }
  )
}

locals {
  shared_services_subnet_rules = [
    {
      name                       = "allow-vnet-inbound"
      priority                   = 100
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "*"
      source_address_prefix      = "VirtualNetwork"
      destination_address_prefix = "VirtualNetwork"
    },
    {
      name                       = "deny-internet-inbound"
      priority                   = 200
      direction                  = "Inbound"
      access                     = "Deny"
      protocol                   = "*"
      source_address_prefix      = "Internet"
      destination_address_prefix = "*"
    },
    {
      name                       = "allow-keyvault-outbound"
      priority                   = 100
      direction                  = "Outbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      destination_port_range     = "443"
      source_address_prefix      = "*"
      destination_address_prefix = "AzureKeyVault"
    },
    {
      name                       = "allow-storage-outbound"
      priority                   = 110
      direction                  = "Outbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      destination_port_range     = "443"
      source_address_prefix      = "*"
      destination_address_prefix = "Storage"
    },
    {
      name                       = "deny-internet-outbound"
      priority                   = 400
      direction                  = "Outbound"
      access                     = "Deny"
      protocol                   = "*"
      source_address_prefix      = "*"
      destination_address_prefix = "Internet"
    },
  ]

  private_endpoints_subnet_rules = [
    {
      name                       = "allow-vnet-inbound"
      priority                   = 100
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "*"
      source_address_prefix      = "VirtualNetwork"
      destination_address_prefix = "VirtualNetwork"
    },
    {
      name                       = "deny-internet-inbound"
      priority                   = 200
      direction                  = "Inbound"
      access                     = "Deny"
      protocol                   = "*"
      source_address_prefix      = "Internet"
      destination_address_prefix = "*"
    },
    {
      name                       = "deny-internet-outbound"
      priority                   = 400
      direction                  = "Outbound"
      access                     = "Deny"
      protocol                   = "*"
      source_address_prefix      = "*"
      destination_address_prefix = "Internet"
    },
  ]

  identity_subnets = {
    shared-services = {
      address_prefixes = [var.services_subnet_cidr]
      nsg_rules        = local.shared_services_subnet_rules
    }
    private-endpoints = {
      address_prefixes                  = [var.private_endpoints_subnet_cidr]
      private_endpoint_network_policies = "Disabled"
      nsg_rules                         = local.private_endpoints_subnet_rules
    }
  }

  encryption_role_assignments = {
    for identity_key, identity in module.shared_identities :
    "${identity_key}_cmk" => {
      scope                = module.key_vault.id
      role_definition_name = "Key Vault Crypto Service Encryption User"
      principal_id         = identity.principal_id
    }
  }
}

module "tags" {
  source              = "../../../../modules/platform-tags"
  environment         = var.environment
  application         = var.application
  created_by          = var.created_by
  business_owner      = var.business_owner
  source_repo         = var.source_repo
  terraform_workspace = var.terraform_workspace
  recovery_tier       = var.recovery_tier
  cost_center         = var.cost_center
  compliance_boundary = var.compliance_boundary
  creation_date_utc   = var.creation_date_utc
  last_modified_utc   = var.last_modified_utc
  additional_tags     = var.additional_tags
}

module "resource_group" {
  source   = "../../../../modules/resource_group"
  name     = var.resource_group_name
  location = var.location
  tags     = module.tags.tags
}

module "identity_network" {
  source              = "../../../../modules/vnet-spoke"
  name                = var.vnet_name
  resource_group_name = module.resource_group.name
  location            = var.location
  address_space       = var.address_space
  subnets             = local.identity_subnets
  tags                = module.tags.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "identity_links" {
  for_each              = data.terraform_remote_state.connectivity.outputs.private_dns_zone_names
  name                  = "link-${var.environment}-${var.application}-${each.key}"
  resource_group_name   = data.terraform_remote_state.connectivity.outputs.resource_group_name
  private_dns_zone_name = each.value
  virtual_network_id    = module.identity_network.vnet_id
  tags                  = module.tags.tags
}

module "hub_to_identity_peering" {
  source = "../../../../modules/vnet-peering"
  providers = {
    azurerm     = azurerm
    azurerm.hub = azurerm
  }
  hub_vnet_id             = data.terraform_remote_state.connectivity.outputs.hub_vnet_id
  hub_vnet_name           = data.terraform_remote_state.connectivity.outputs.hub_vnet_name
  hub_rg_name             = data.terraform_remote_state.connectivity.outputs.resource_group_name
  spoke_vnet_id           = module.identity_network.vnet_id
  spoke_vnet_name         = module.identity_network.vnet_name
  spoke_rg_name           = module.resource_group.name
  allow_forwarded_traffic = true
  allow_gateway_transit   = false
  use_remote_gateways     = false
}

#checkov:skip=CKV2_AZURE_32: The Key Vault private endpoint is provisioned separately in this identity stack.
module "key_vault" {
  source                        = "../../../../modules/keyvault"
  name                          = var.key_vault_name
  resource_group_name           = module.resource_group.name
  location                      = var.location
  tenant_id                     = data.azurerm_client_config.current.tenant_id
  sku_name                      = "premium"
  enable_rbac_authorization     = true
  public_network_access_enabled = false
  network_acls_bypass           = "AzureServices"
  tags                          = module.tags.tags
}

module "shared_identities" {
  for_each            = var.shared_identity_names
  source              = "../../../../modules/user-assigned-identity"
  name                = each.value
  resource_group_name = module.resource_group.name
  location            = var.location
  tags                = module.tags.tags
}

module "shared_services_cmk" {
  source        = "../../../../modules/keyvault-key"
  name          = "cmk-${var.environment}-${var.application}"
  key_vault_id  = module.key_vault.id
  key_vault_uri = module.key_vault.vault_uri
  key_type      = "RSA-HSM"
  key_size      = 2048
  key_ops       = ["decrypt", "encrypt", "sign", "unwrapKey", "verify", "wrapKey"]
}

module "role_assignments" {
  source      = "../../../../modules/role-assignments"
  assignments = local.encryption_role_assignments
}

module "key_vault_private_endpoint" {
  source               = "../../../../modules/private-endpoint"
  name                 = "pe-kv-${var.environment}-${var.application}"
  resource_group_name  = module.resource_group.name
  location             = var.location
  subnet_id            = module.identity_network.subnet_ids["private-endpoints"]
  target_resource_id   = module.key_vault.id
  subresource_names    = ["vault"]
  private_dns_zone_ids = [data.terraform_remote_state.connectivity.outputs.private_dns_zone_ids["keyvault"]]
  tags                 = module.tags.tags
}

resource "azurerm_management_lock" "resource_group" {
  name       = "lock-${var.resource_group_name}"
  scope      = module.resource_group.id
  lock_level = "CanNotDelete"
  notes      = "Identity stack contains shared managed identities and the platform CMK Key Vault. Accidental deletion would break encryption for all workloads consuming the shared CMK."
}

module "key_vault_diagnostics" {
  source                     = "../../../../modules/diagnostics-1"
  name                       = "diag-kv-${var.environment}-${var.application}"
  target_resource_id         = module.key_vault.id
  log_analytics_workspace_id = data.terraform_remote_state.management.outputs.workspace_id
  enabled_logs               = ["AuditEvent"]
  enabled_metrics            = ["AllMetrics"]
}
