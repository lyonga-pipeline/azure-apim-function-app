data "azurerm_client_config" "current" {}

data "terraform_remote_state" "subscriptions" {
  count   = var.use_subscriptions_state ? 1 : 0
  backend = "azurerm"

  config = merge(
    {
      resource_group_name  = var.subscriptions_state_rg
      storage_account_name = var.subscriptions_state_sa
      container_name       = var.subscriptions_state_container
      key                  = var.subscriptions_state_key
      use_azuread_auth     = true
    },
    coalesce(var.subscriptions_state_subscription_id, var.platform_state_subscription_id) == null ? {} : {
      subscription_id = coalesce(var.subscriptions_state_subscription_id, var.platform_state_subscription_id)
    }
  )
}

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

data "terraform_remote_state" "identity" {
  count   = var.use_shared_identity_services ? 1 : 0
  backend = "azurerm"

  config = merge(
    {
      resource_group_name  = coalesce(var.identity_state_rg, var.management_state_rg)
      storage_account_name = coalesce(var.identity_state_sa, var.management_state_sa)
      container_name       = var.identity_state_container
      key                  = coalesce(var.identity_state_key, "stacks/dev/platform-v2/identity.tfstate")
      use_azuread_auth     = true
    },
    coalesce(var.identity_state_subscription_id, var.platform_state_subscription_id) == null ? {} : {
      subscription_id = coalesce(var.identity_state_subscription_id, var.platform_state_subscription_id)
    }
  )
}

locals {
  placeholder_guid                = "11111111-1111-1111-1111-111111111111"
  placeholder_secondary_guid      = "22222222-2222-2222-2222-222222222222"
  placeholder_resource_group_name = "rg-placeholder-platform"
  placeholder_hub_vnet_name       = "vnet-placeholder-hub"
  placeholder_hub_vnet_id         = "/subscriptions/${var.subscription_id}/resourceGroups/${local.placeholder_resource_group_name}/providers/Microsoft.Network/virtualNetworks/${local.placeholder_hub_vnet_name}"
  placeholder_workspace_id        = "/subscriptions/${var.subscription_id}/resourceGroups/${local.placeholder_resource_group_name}/providers/Microsoft.OperationalInsights/workspaces/law-placeholder-platform"
  placeholder_key_vault_key_id    = "https://kv-placeholder.vault.azure.net/keys/cmk-placeholder/${local.placeholder_guid}"
  placeholder_shared_identity_id  = "/subscriptions/${var.subscription_id}/resourceGroups/${local.placeholder_resource_group_name}/providers/Microsoft.ManagedIdentity/userAssignedIdentities/uai-placeholder-runtime"
  placeholder_private_dns_zone_ids = {
    blob       = "/subscriptions/${var.subscription_id}/resourceGroups/${local.placeholder_resource_group_name}/providers/Microsoft.Network/privateDnsZones/privatelink.blob.core.windows.net"
    file       = "/subscriptions/${var.subscription_id}/resourceGroups/${local.placeholder_resource_group_name}/providers/Microsoft.Network/privateDnsZones/privatelink.file.core.windows.net"
    queue      = "/subscriptions/${var.subscription_id}/resourceGroups/${local.placeholder_resource_group_name}/providers/Microsoft.Network/privateDnsZones/privatelink.queue.core.windows.net"
    table      = "/subscriptions/${var.subscription_id}/resourceGroups/${local.placeholder_resource_group_name}/providers/Microsoft.Network/privateDnsZones/privatelink.table.core.windows.net"
    keyvault   = "/subscriptions/${var.subscription_id}/resourceGroups/${local.placeholder_resource_group_name}/providers/Microsoft.Network/privateDnsZones/privatelink.vaultcore.azure.net"
    appconfig  = "/subscriptions/${var.subscription_id}/resourceGroups/${local.placeholder_resource_group_name}/providers/Microsoft.Network/privateDnsZones/privatelink.azconfig.io"
    servicebus = "/subscriptions/${var.subscription_id}/resourceGroups/${local.placeholder_resource_group_name}/providers/Microsoft.Network/privateDnsZones/privatelink.servicebus.windows.net"
    sql        = "/subscriptions/${var.subscription_id}/resourceGroups/${local.placeholder_resource_group_name}/providers/Microsoft.Network/privateDnsZones/privatelink.database.windows.net"
    websites   = "/subscriptions/${var.subscription_id}/resourceGroups/${local.placeholder_resource_group_name}/providers/Microsoft.Network/privateDnsZones/privatelink.azurewebsites.net"
  }
  placeholder_private_dns_zone_names = {
    blob       = "privatelink.blob.core.windows.net"
    file       = "privatelink.file.core.windows.net"
    queue      = "privatelink.queue.core.windows.net"
    table      = "privatelink.table.core.windows.net"
    keyvault   = "privatelink.vaultcore.azure.net"
    appconfig  = "privatelink.azconfig.io"
    servicebus = "privatelink.servicebus.windows.net"
    sql        = "privatelink.database.windows.net"
    websites   = "privatelink.azurewebsites.net"
  }

  subscriptions_outputs_raw = try(data.terraform_remote_state.subscriptions[0].outputs, {})
  subscriptions_catalog     = var.use_subscriptions_state ? tomap(try(local.subscriptions_outputs_raw.subscription_catalog, {})) : tomap({})
  expected_subscription_id = try(
    local.subscriptions_catalog[var.subscription_catalog_entry_key].existing_subscription_id,
    null,
  )

  connectivity_outputs_raw = try(data.terraform_remote_state.connectivity.outputs, {})
  management_outputs_raw   = try(data.terraform_remote_state.management.outputs, {})
  identity_outputs_raw     = try(data.terraform_remote_state.identity[0].outputs, {})

  connectivity_outputs = {
    resource_group_name    = try(local.connectivity_outputs_raw.resource_group_name, local.placeholder_resource_group_name)
    hub_vnet_id            = try(local.connectivity_outputs_raw.hub_vnet_id, local.placeholder_hub_vnet_id)
    hub_vnet_name          = try(local.connectivity_outputs_raw.hub_vnet_name, local.placeholder_hub_vnet_name)
    private_dns_zone_ids   = try(local.connectivity_outputs_raw.private_dns_zone_ids, local.placeholder_private_dns_zone_ids)
    private_dns_zone_names = try(local.connectivity_outputs_raw.private_dns_zone_names, local.placeholder_private_dns_zone_names)
  }

  management_outputs = {
    resource_group_name = try(local.management_outputs_raw.resource_group_name, local.placeholder_resource_group_name)
    workspace_id        = try(local.management_outputs_raw.workspace_id, local.placeholder_workspace_id)
  }

  identity_outputs = {
    shared_identity_ids = var.use_shared_identity_services ? tomap(try(local.identity_outputs_raw.shared_identity_ids, {
      (var.shared_identity_workload_identity_key) = local.placeholder_shared_identity_id
    })) : tomap({})
    shared_identity_client_ids = var.use_shared_identity_services ? tomap(try(local.identity_outputs_raw.shared_identity_client_ids, {
      (var.shared_identity_workload_identity_key) = local.placeholder_guid
    })) : tomap({})
    shared_identity_principal_ids = var.use_shared_identity_services ? tomap(try(local.identity_outputs_raw.shared_identity_principal_ids, {
      (var.shared_identity_workload_identity_key) = local.placeholder_secondary_guid
    })) : tomap({})
    shared_identity_names = var.use_shared_identity_services ? tomap(try(local.identity_outputs_raw.shared_identity_names, {
      (var.shared_identity_workload_identity_key) = "uai-placeholder-runtime"
    })) : tomap({})
    shared_services_cmk_key_id = var.use_shared_identity_services ? try(local.identity_outputs_raw.shared_services_cmk_key_id, local.placeholder_key_vault_key_id) : null
  }

  dependency_errors = compact(concat(
    !var.use_subscriptions_state ? [] : length(keys(local.subscriptions_catalog)) > 0 ? [] : [
      "Apply global/subscriptions before planning workload-v2/finserv-api, or disable use_subscriptions_state if you intentionally are not using the central subscription catalog.",
    ],
    !var.use_subscriptions_state ? [] : local.expected_subscription_id != null ? [] : [
      "The subscriptions stack does not contain an entry for subscription_catalog_entry_key = ${var.subscription_catalog_entry_key}.",
    ],
    !var.use_subscriptions_state || local.expected_subscription_id == "" || local.expected_subscription_id == var.subscription_id ? [] : [
      "The workload stack subscription_id does not match the central subscriptions catalog.",
    ],
    length(keys(local.connectivity_outputs_raw)) > 0 ? [] : [
      "Apply platform-v2/connectivity before planning workload-v2/finserv-api. Reading the state blob alone is not enough; the stack must be applied so outputs are written to state.",
    ],
    contains(keys(local.connectivity_outputs_raw), "resource_group_name") ? [] : [
      "Connectivity state is missing resource_group_name. Apply platform-v2/connectivity so outputs are persisted.",
    ],
    contains(keys(local.connectivity_outputs_raw), "hub_vnet_id") ? [] : [
      "Connectivity state is missing hub_vnet_id. Apply platform-v2/connectivity so outputs are persisted.",
    ],
    contains(keys(local.connectivity_outputs_raw), "hub_vnet_name") ? [] : [
      "Connectivity state is missing hub_vnet_name. Apply platform-v2/connectivity so outputs are persisted.",
    ],
    contains(keys(local.connectivity_outputs_raw), "private_dns_zone_ids") ? [] : [
      "Connectivity state is missing private_dns_zone_ids. Apply platform-v2/connectivity so outputs are persisted.",
    ],
    contains(keys(local.connectivity_outputs_raw), "private_dns_zone_names") ? [] : [
      "Connectivity state is missing private_dns_zone_names. Apply platform-v2/connectivity so outputs are persisted.",
    ],
    length(keys(local.management_outputs_raw)) > 0 ? [] : [
      "Apply platform-v2/management before planning workload-v2/finserv-api.",
    ],
    contains(keys(local.management_outputs_raw), "workspace_id") ? [] : [
      "Management state is missing workspace_id. Apply platform-v2/management so outputs are persisted.",
    ],
    contains(keys(local.management_outputs_raw), "resource_group_name") ? [] : [
      "Management state is missing resource_group_name. Apply platform-v2/management so outputs are persisted.",
    ],
    !var.use_shared_identity_services ? [] : length(keys(local.identity_outputs_raw)) > 0 ? [] : [
      "Apply platform-v2/identity before planning workload-v2/finserv-api when use_shared_identity_services = true.",
    ],
    !var.use_shared_identity_services || contains(keys(local.identity_outputs_raw), "shared_identity_ids") ? [] : [
      "Identity state is missing shared_identity_ids. Apply platform-v2/identity so outputs are persisted.",
    ],
    !var.use_shared_identity_services || contains(keys(local.identity_outputs_raw), "shared_identity_client_ids") ? [] : [
      "Identity state is missing shared_identity_client_ids. Apply platform-v2/identity so outputs are persisted.",
    ],
    !var.use_shared_identity_services || contains(keys(local.identity_outputs_raw), "shared_identity_principal_ids") ? [] : [
      "Identity state is missing shared_identity_principal_ids. Apply platform-v2/identity so outputs are persisted.",
    ],
    !var.use_shared_identity_services || contains(keys(local.identity_outputs_raw), "shared_identity_names") ? [] : [
      "Identity state is missing shared_identity_names. Apply platform-v2/identity so outputs are persisted.",
    ],
    !var.use_shared_identity_services || contains(keys(local.identity_outputs_raw), "shared_services_cmk_key_id") ? [] : [
      "Identity state is missing shared_services_cmk_key_id. Apply platform-v2/identity so outputs are persisted.",
    ]
  ))
}

resource "terraform_data" "dependency_guard" {
  input = true

  lifecycle {
    precondition {
      condition     = length(local.dependency_errors) == 0
      error_message = join("\n", local.dependency_errors)
    }
  }
}
