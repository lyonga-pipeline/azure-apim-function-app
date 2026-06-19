module "tags" {
  source = "../../../modules/platform-tags"

  environment         = var.environment
  application         = var.platform_tags.application
  business_owner      = var.platform_tags.business_owner
  source_repo         = var.platform_tags.source_repo
  terraform_workspace = var.platform_tags.terraform_workspace
  recovery_tier       = var.platform_tags.recovery_tier
  cost_center         = var.platform_tags.cost_center
  data_classification = var.platform_tags.data_classification
  compliance_boundary = var.platform_tags.compliance_boundary
  additional_tags     = var.platform_tags.additional_tags
}

module "resource_group" {
  source = "../../../modules/resource-group"

  name     = var.resource_group.name
  location = var.location
  tags     = module.tags.tags
}

module "log_analytics" {
  source = "../../../modules/log-analytics"

  name                = var.log_analytics.name
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  retention_in_days   = var.log_analytics.retention_in_days
  daily_quota_gb      = try(var.log_analytics.daily_quota_gb, null)
  tags                = module.tags.tags
}

module "action_group" {
  source = "../../../modules/action-group"

  name                = var.action_group.name
  resource_group_name = module.resource_group.name
  short_name          = var.action_group.short_name
  receivers           = var.action_group.receivers
  tags                = module.tags.tags
}

