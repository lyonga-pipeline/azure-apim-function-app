locals {
  tags = merge({
    ManagedBy = "Terraform"
    IaCSource = "AVM"
    Phase     = "2"
    Workload  = "avd"
  }, var.tags)
}

module "avd_management_plane" {
  source  = "Azure/avm-ptn-avd-lza-managementplane/azurerm"
  version = "0.3.2"

  resource_group_name = var.resource_group_name

  virtual_desktop_application_group_location = var.location
  virtual_desktop_application_group_name     = var.application_group.name
  virtual_desktop_application_group_type     = var.application_group.type
  virtual_desktop_application_group_tags     = local.tags

  virtual_desktop_host_pool_location            = var.location
  virtual_desktop_host_pool_resource_group_name = var.resource_group_name
  virtual_desktop_host_pool_name                = var.host_pool.name
  virtual_desktop_host_pool_type                = var.host_pool.type
  virtual_desktop_host_pool_load_balancer_type  = var.host_pool.load_balancer_type
  virtual_desktop_host_pool_tags                = local.tags

  virtual_desktop_scaling_plan_location            = var.location
  virtual_desktop_scaling_plan_resource_group_name = var.resource_group_name
  virtual_desktop_scaling_plan_name                = var.scaling_plan.name
  virtual_desktop_scaling_plan_time_zone           = var.scaling_plan.time_zone
  virtual_desktop_scaling_plan_schedule            = var.scaling_plan.schedule
  virtual_desktop_scaling_plan_tags                = local.tags

  virtual_desktop_workspace_location                      = var.location
  virtual_desktop_workspace_name                          = var.workspace.name
  virtual_desktop_workspace_public_network_access_enabled = var.workspace.public_network_access_enabled
  virtual_desktop_workspace_tags                          = local.tags

  private_endpoints = var.private_endpoints
  role_assignments  = var.role_assignments
  enable_telemetry  = var.enable_telemetry
}

module "operational_contracts" {
  source  = "app.terraform.io/Compeer-Financial-Services/compeer-operational-contracts/azurerm"
  version = "1.0.0"

  contracts = var.operational_contracts
}
