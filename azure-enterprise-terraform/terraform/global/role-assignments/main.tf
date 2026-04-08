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

  # Key alignment note: the management_groups module (modules/management_groups/main.tf)
  # outputs exactly these keys: platform, connectivity, management, identity, security,
  # landing_zones, prod, nonprod, sandbox, decommissioned.
  # All keys referenced below ("platform", "security", "nonprod", "prod") are present
  # in that output. compact() removes nulls — error strings are NOT removed — so a
  # missing key will surface an error at plan time, not be silently swallowed.
  dependency_errors = compact([
    length(keys(local.management_group_ids)) > 0 ? null : "Apply global/management-groups before planning or applying global/role-assignments.",
    contains(keys(local.management_group_ids), "platform") ? null : "Management groups state is missing the platform management group id.",
    contains(keys(local.management_group_ids), "security") ? null : "Management groups state is missing the security management group id.",
    contains(keys(local.management_group_ids), "nonprod") ? null : "Management groups state is missing the nonprod management group id.",
    contains(keys(local.management_group_ids), "prod") ? null : "Management groups state is missing the prod management group id.",
  ])

  # ABAC condition restricts what roles a User Access Administrator can re-delegate.
  # Without this condition, UAA at management group scope is functionally equivalent
  # to Owner and is a privilege-escalation finding in finserv audits.
  # This condition limits delegation to Contributor and Reader only — deployers cannot
  # grant each other Owner, UAA, or custom privileged roles.
  uaa_abac_condition         = "((!(ActionMatches{'Microsoft.Authorization/roleAssignments/write'})) OR (@Request[Microsoft.Authorization/roleAssignments:RoleDefinitionId] ForAnyOfAnyValues:GuidEquals {b24988ac-6180-42a0-ab88-20f7382dd24c, acdd72a7-3385-48ef-bd42-f606fba81ae7})) AND ((!(ActionMatches{'Microsoft.Authorization/roleAssignments/delete'})) OR (@Resource[Microsoft.Authorization/roleAssignments:RoleDefinitionId] ForAnyOfAnyValues:GuidEquals {b24988ac-6180-42a0-ab88-20f7382dd24c, acdd72a7-3385-48ef-bd42-f606fba81ae7}))"
  uaa_abac_condition_version = "2.0"

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
        condition            = local.uaa_abac_condition
        condition_version    = local.uaa_abac_condition_version
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
        condition            = local.uaa_abac_condition
        condition_version    = local.uaa_abac_condition_version
      }
    },
    var.nonprod_workload_deployer_principal_id == "" ? {} : {
      nonprod_contributor = {
        scope                = local.management_group_ids["nonprod"]
        role_definition_name = "Contributor"
        principal_id         = var.nonprod_workload_deployer_principal_id
      }
      nonprod_user_access_admin = {
        scope                = local.management_group_ids["nonprod"]
        role_definition_name = "User Access Administrator"
        principal_id         = var.nonprod_workload_deployer_principal_id
        condition            = local.uaa_abac_condition
        condition_version    = local.uaa_abac_condition_version
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
        condition            = local.uaa_abac_condition
        condition_version    = local.uaa_abac_condition_version
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
