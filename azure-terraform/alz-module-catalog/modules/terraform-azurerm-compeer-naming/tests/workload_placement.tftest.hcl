run "new_workload_placement_uses_appendix_f_names" {
  command = plan
  variables {
    scope                        = "workload"
    region                       = "centralus"
    environment                  = "prod"
    domain                       = "internal-apps"
    appcode                      = "orders"
    workload_stem_include_domain = false
    resource_group_keys          = ["network", "security", "app"]
  }
  assert {
    condition     = output.resource_group_names.app == "orders-cus-prod-app-rg" && output.resource_group_names.network == "orders-cus-prod-network-rg" && output.workload_vnet == "orders-cus-prod-spoke-vnet"
    error_message = "New workload names must match Appendix F and refined placement without a domain prefix."
  }
}

run "existing_workload_naming_stays_compatible_by_default" {
  command = plan
  variables {
    scope               = "workload"
    region              = "centralus"
    environment         = "prod"
    domain              = "internal-apps"
    appcode             = "orders"
    resource_group_keys = ["application"]
  }
  assert {
    condition     = output.resource_group_names.application == "internal-apps-orders-cus-prod-application-rg"
    error_message = "Do not silently rename other existing naming-module consumers."
  }
}
