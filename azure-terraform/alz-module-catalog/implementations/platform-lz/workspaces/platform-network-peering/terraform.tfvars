# Deployable tfvars for this workspace.
#
# Auth is NOT set here:
#   tenant_id            -> shared HCP variable set (Terraform category, key: tenant_id)
#   hub_subscription_id  -> this workspace's Terraform-category variable in HCP
#   spoke_subscription_id-> this workspace's Terraform-category variable in HCP
#

network_peering = {
  enabled                              = false
  use_tfe_outputs                      = true
  tfe_organization                     = "Compeer-Financial-Services"
  platform_connectivity_workspace_name = "platform-connectivity"
  workload_spoke_workspace_name        = "workload-spoke-internal-apps-prod"
  peering_name_prefix                  = "internal-apps-prod"
  hub_to_spoke                         = {}
  spoke_to_hub                         = {}
  private_dns_zones                    = {}
  tags = {
    managed_by = "terraform"
  }
}
