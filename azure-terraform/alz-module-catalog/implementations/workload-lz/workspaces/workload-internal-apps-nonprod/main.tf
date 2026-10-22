data "tfe_outputs" "management" {
  count        = local.enabled && var.use_tfe_outputs && var.tfe_organization != null ? 1 : 0
  organization = var.tfe_organization
  workspace    = var.management_workspace_name
}
data "tfe_outputs" "connectivity" {
  count        = local.enabled && var.use_tfe_outputs && var.tfe_organization != null ? 1 : 0
  organization = var.tfe_organization
  workspace    = var.connectivity_workspace_name
}

data "tfe_outputs" "governance" {
  count        = local.enabled && var.use_tfe_outputs && var.tfe_organization != null ? 1 : 0
  organization = var.tfe_organization
  workspace    = var.governance_workspace_name
}

resource "time_static" "deployment_created" {
  count = local.enabled ? 1 : 0
}

module "blueprint" {
  # Promote this exact release independently of every other environment.
  source = "https://codeload.github.com/lyonga-pipeline/azure-apim-function-app/zip/99aa3e60e07b7e7fa91ac7a6f4bbbc0ea05f28df//azure-apim-function-app-99aa3e60e07b7e7fa91ac7a6f4bbbc0ea05f28df/azure-terraform/alz-module-catalog/patterns/terraform-azurerm-compeer-spoke-landing-zone?archive=zip"
  count  = local.enabled ? 1 : 0
  providers = {
    azurerm     = azurerm
    azurerm.dns = azurerm.dns
  }
  subscription_id = var.subscription_id
  tenant_id       = var.tenant_id
  environment     = var.environment
  location        = try(var.spoke.location, "centralus")
  appcode         = try(var.spoke.appcode, "replace")
  domain          = try(var.spoke.domain, "internal-apps")
  workload_tags = merge(try(var.spoke.workload_tags, {}), {
    created_on = try(formatdate("YYYY-MM-DD", time_static.deployment_created[0].rfc3339), "2000-01-01")
  })
  platform                      = local.platform
  address_space                 = try(var.spoke.address_space, [])
  reserved_address_spaces       = try(var.spoke.reserved_address_spaces, [])
  inspection_address_prefixes   = try(var.spoke.inspection_address_prefixes, [])
  subnets                       = try(var.spoke.subnets, {})
  egress_next_hop_ip            = try(var.spoke.egress_next_hop_ip, "unset")
  allow_azure_provided_dns      = try(var.spoke.allow_azure_provided_dns, false)
  manage_hub_attachment         = try(var.spoke.manage_hub_attachment, false)
  gateway_transit_enabled       = try(var.spoke.gateway_transit_enabled, false)
  private_endpoint_client_cidrs = try(var.spoke.private_endpoint_client_cidrs, [])
  key_vault                     = try(var.spoke.key_vault, {})
  workload_access_group_ids     = try(var.spoke.workload_access_group_ids, {})
  operations = {
    create_action_group = try(var.spoke.operations.create_action_group, false)
    platform_action_group_keys = try(var.spoke.operations.platform_action_group_keys,
      try(var.spoke.monitoring.existing_failed_requests_alert, null) == null && !try(var.spoke.operations.create_action_group, false) && length(try(var.spoke.operations.action_group_ids, [])) == 0 && contains(keys(local.platform.action_group_ids), "primary") ? ["primary"] : []
    )
    notification_emails = try(var.spoke.operations.notification_emails, [])
    action_group_ids    = try(var.spoke.operations.action_group_ids, [])
  }
  monitoring       = try(var.spoke.monitoring, {})
  diagnostics      = try(var.spoke.diagnostics, {})
  storage_accounts = try(var.spoke.storage_accounts, {})
  backup           = try(var.spoke.backup, null)
  depends_on       = [terraform_data.deployment_contract]
}
