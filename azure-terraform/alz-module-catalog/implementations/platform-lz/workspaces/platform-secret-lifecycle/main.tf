# Use this same root in separate prod and nonprod HCP workspaces.
module "lifecycle" {
  source                            = "../../../../patterns/terraform-azurerm-compeer-secret-lifecycle"
  environment                       = var.environment
  location                          = var.location
  tenant_id                         = var.tenant_id
  resource_group_name               = var.resource_group_name
  names                             = var.names
  tags                              = var.tags
  integration_subnet_id             = var.integration_subnet_id
  private_endpoint_subnet_id        = var.private_endpoint_subnet_id
  private_dns_zone_ids              = var.private_dns_zone_ids
  dns_owned_by_policy               = var.dns_owned_by_policy
  log_analytics_workspace_id        = var.log_analytics_workspace_id
  action_group_ids                  = var.action_group_ids
  manual_api_client_id              = var.manual_api_client_id
  operator_group_ids                = var.operator_group_ids
  event_delivery_exception_approved = var.event_delivery_exception_approved
  package_path                      = var.package_path
  consumer_hosts                    = var.consumer_hosts
  vaults                            = var.vaults
  assets                            = var.assets
  manual_approvals                  = var.manual_approvals
}
output "enrollment" { value = module.lifecycle.enrollment }
output "worker_identity" { value = module.lifecycle.worker_identity }
output "manual_request_url" { value = module.lifecycle.manual_request_url }
output "function_app_ids" { value = module.lifecycle.function_app_ids }
