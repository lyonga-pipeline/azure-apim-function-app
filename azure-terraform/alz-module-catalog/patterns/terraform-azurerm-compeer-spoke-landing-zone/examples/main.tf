resource "terraform_data" "approval" {
  count = var.enabled ? 1 : 0
  lifecycle {
    precondition {
      condition     = var.deployment_approved
      error_message = "Examples contain synthetic values. Replace them, obtain IPAM/security/operations approval, review the plan, then explicitly set deployment_approved=true."
    }
  }
}

module "blueprint" {
  source                        = "../"
  count                         = var.enabled ? 1 : 0
  providers                     = { azurerm = azurerm, azurerm.dns = azurerm.dns }
  subscription_id               = var.subscription_id
  tenant_id                     = var.tenant_id
  environment                   = var.environment
  location                      = var.spoke.location
  appcode                       = var.spoke.appcode
  domain                        = var.spoke.domain
  workload_tags                 = var.spoke.workload_tags
  platform                      = var.platform
  address_space                 = var.spoke.address_space
  reserved_address_spaces       = var.spoke.reserved_address_spaces
  inspection_address_prefixes   = var.spoke.inspection_address_prefixes
  subnets                       = var.spoke.subnets
  egress_next_hop_ip            = var.spoke.egress_next_hop_ip
  allow_azure_provided_dns      = false
  manage_hub_attachment         = false
  gateway_transit_enabled       = false
  private_endpoint_client_cidrs = var.spoke.private_endpoint_client_cidrs
  workload_access_group_ids     = var.spoke.workload_access_group_ids
  key_vault                     = var.key_vault
  diagnostics                   = var.diagnostics
  operations                    = var.operations
  monitoring                    = var.monitoring
  storage_accounts              = var.storage_accounts
  backup                        = var.backup
  depends_on                    = [terraform_data.approval]
}
