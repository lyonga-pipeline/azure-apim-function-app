data "terraform_remote_state" "management_groups" {
  backend = "azurerm"

  config = {
    resource_group_name  = var.management_groups_state_rg
    storage_account_name = var.management_groups_state_sa
    container_name       = var.management_groups_state_container
    key                  = var.management_groups_state_key
    subscription_id      = var.management_groups_state_subscription_id
    use_azuread_auth     = true
  }
}

locals {
  management_group_ids = try(data.terraform_remote_state.management_groups.outputs.management_group_ids, {})

  dependency_errors = compact([
    length(keys(local.management_group_ids)) > 0 ? null : "Apply global/management-groups before planning or applying global/role-assignments.",
    contains(keys(local.management_group_ids), "platform") ? null : "Management groups state is missing the platform management group id.",
    contains(keys(local.management_group_ids), "security") ? null : "Management groups state is missing the security management group id.",
    contains(keys(local.management_group_ids), "nonprod") ? null : "Management groups state is missing the nonprod management group id.",
    contains(keys(local.management_group_ids), "prod") ? null : "Management groups state is missing the prod management group id.",
  ])

  role_assignments = merge(
    var.platform_deployer_principal_id == "" ? {} : {
      platform_contributor = {
        scope                = local.management_group_ids["platform"]
        role_definition_name = "Contributor"
        principal_id         = var.platform_deployer_principal_id
      }
      platform_user_access_admin = {
        scope                = local.management_group_ids["platform"]
        role_definition_name = "User Access Administrator"
        principal_id         = var.platform_deployer_principal_id
      }
    },
    var.security_reader_principal_id == "" ? {} : {
      security_reader = {
        scope                = local.management_group_ids["security"]
        role_definition_name = "Reader"
        principal_id         = var.security_reader_principal_id
      }
    },
    var.security_deployer_principal_id == "" ? {} : {
      security_contributor = {
        scope                = local.management_group_ids["security"]
        role_definition_name = "Contributor"
        principal_id         = var.security_deployer_principal_id
      }
      security_user_access_admin = {
        scope                = local.management_group_ids["security"]
        role_definition_name = "User Access Administrator"
        principal_id         = var.security_deployer_principal_id
      }
    },
    var.nonprod_workload_deployer_principal_id == "" ? {} : {
      nonprod_contributor = {
        scope                = local.management_group_ids["nonprod"]
        role_definition_name = "Contributor"
        principal_id         = var.nonprod_workload_deployer_principal_id
      }
    },
    var.prod_workload_deployer_principal_id == "" ? {} : {
      prod_contributor = {
        scope                = local.management_group_ids["prod"]
        role_definition_name = "Contributor"
        principal_id         = var.prod_workload_deployer_principal_id
      }
      prod_user_access_admin = {
        scope                = local.management_group_ids["prod"]
        role_definition_name = "User Access Administrator"
        principal_id         = var.prod_workload_deployer_principal_id
      }
    },
    var.prod_workload_reader_principal_id == "" ? {} : {
      prod_reader = {
        scope                = local.management_group_ids["prod"]
        role_definition_name = "Reader"
        principal_id         = var.prod_workload_reader_principal_id
      }
    },
  )
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

module "role_assignments" {
  source      = "../../modules/role-assignments"
  assignments = local.role_assignments

  depends_on = [terraform_data.dependency_guard]
}
