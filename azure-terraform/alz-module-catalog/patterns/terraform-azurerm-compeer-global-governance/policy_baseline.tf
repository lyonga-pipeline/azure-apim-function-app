# =============================================================================
# Built-in policy baseline bundle
#
# The Compeer landing-zone deny/audit baseline, shipped as code so the
# deployable governance workspace gets real policy instead of an empty map.
# Toggle with var.policy_baseline. Everything here merges into the pattern's
# existing custom_policy_definitions / management_group_policy_assignments maps
# (var.* still works for anything hand-authored on top).
#
# Effect defaults to "Audit" per deploy-runbook.tf §2.4 - promote to "Deny"
# per policy after the false-positive review and once an exemption path exists
# (see platform-policy pattern for exemptions + remediation).
# =============================================================================

locals {
  pb            = var.policy_baseline
  pb_enabled    = try(local.pb.enabled, false)
  pb_mg_key     = try(local.pb.management_group_key, null)
  pb_mg_id      = local.pb_mg_key == null ? null : local.management_group_scope_ids[local.pb_mg_key]
  pb_effect     = try(local.pb.effect, "Audit")
  pb_enforce    = try(local.pb.enforce, true)
  pb_not_scopes = try(local.pb.not_scopes, [])
  pb_locations  = try(local.pb.allowed_locations, ["centralus"])
  pb_required_tags = try(local.pb.required_tag_names, [
    "env", "application", "bt_owner", "source_repo", "tf_workspace",
    "recovery", "cost_center", "data_classification", "compliance_boundary",
  ])
  pb_assign_mcsb = try(local.pb.assign_security_benchmark, true)
  # Resource groups carved out of deny-public-PaaS / secure-storage - the
  # documented exception path for e.g. the Palo Alto bootstrap RG. Resources in
  # these RGs still get diagnostics + Defender; they just don't trip the
  # public-network-access deny. Keep this list short and reviewed.
  pb_exempt_rgs = try(local.pb.exempt_resource_group_names, [])
  # Microsoft Cloud Security Benchmark - stable built-in initiative ID.
  pb_mcsb_id = "/providers/Microsoft.Authorization/policySetDefinitions/1f3afdf9-d0c9-4c3d-847f-89da613e70a8"

  _pb_effect_param = {
    type          = "String"
    defaultValue  = "Audit"
    allowedValues = ["Audit", "Deny", "Disabled"]
    metadata      = { displayName = "Effect" }
  }
  _pb_exempt_rgs_param = {
    type         = "Array"
    defaultValue = []
    metadata     = { displayName = "Exempt resource group names" }
  }
  # `not { resourceGroup in ... }` clause added to the deny-public rules.
  _pb_rg_not_exempt = { not = { field = "resourceGroup", in = "[parameters('exemptResourceGroups')]" } }
  _pb_meta          = { category = "Compeer Landing Zone", version = "1.1.0" }

  pb_definitions = { for k, v in local.pb_definitions_all : k => v if local.pb_enabled }
  pb_definitions_all = {
    "cmp-allowed-locations" = {
      display_name         = "Compeer - Allowed Azure regions"
      management_group_key = local.pb_mg_key
      description          = "Restricts landing-zone deployments to approved Compeer regions."
      metadata             = local._pb_meta
      parameters = {
        allowedLocations = { type = "Array", metadata = { displayName = "Allowed locations" } }
        effect           = local._pb_effect_param
      }
      policy_rule = {
        if = { allOf = [
          { field = "location", exists = "true" },
          { field = "location", notIn = "[parameters('allowedLocations')]" },
          { field = "location", notEquals = "global" },
        ] }
        then = { effect = "[parameters('effect')]" }
      }
    }
    "cmp-required-tags" = {
      display_name         = "Compeer - Require standard resource tags"
      management_group_key = local.pb_mg_key
      description          = "Requires standard ownership, cost, data, and recovery tags."
      metadata             = local._pb_meta
      parameters = {
        requiredTagNames = { type = "Array", metadata = { displayName = "Required tag names" } }
        effect           = local._pb_effect_param
      }
      policy_rule = {
        if = {
          count = {
            value = "[parameters('requiredTagNames')]"
            name  = "requiredTagName"
            where = { value = "[contains(field('tags'), current('requiredTagName'))]", equals = false }
          }
          greater = 0
        }
        then = { effect = "[parameters('effect')]" }
      }
    }
    "cmp-deny-public-paas" = {
      display_name         = "Compeer - Deny public network access for sensitive PaaS"
      management_group_key = local.pb_mg_key
      description          = "Denies public network exposure for common sensitive PaaS resources, except in explicitly exempt resource groups."
      metadata             = local._pb_meta
      parameters = {
        effect               = local._pb_effect_param
        exemptResourceGroups = local._pb_exempt_rgs_param
      }
      policy_rule = {
        if = { allOf = [
          local._pb_rg_not_exempt,
          { anyOf = [
            { allOf = [{ field = "type", equals = "Microsoft.Storage/storageAccounts" }, { field = "Microsoft.Storage/storageAccounts/publicNetworkAccess", notEquals = "Disabled" }] },
            { allOf = [{ field = "type", equals = "Microsoft.KeyVault/vaults" }, { field = "Microsoft.KeyVault/vaults/publicNetworkAccess", notEquals = "Disabled" }] },
            { allOf = [{ field = "type", equals = "Microsoft.Web/sites" }, { field = "Microsoft.Web/sites/publicNetworkAccess", notEquals = "Disabled" }] },
          ] },
        ] }
        then = { effect = "[parameters('effect')]" }
      }
    }
    "cmp-secure-storage" = {
      display_name         = "Compeer - Enforce secure storage account baseline"
      management_group_key = local.pb_mg_key
      description          = "Requires HTTPS-only storage, TLS 1.2+, and no blob public access, except in explicitly exempt resource groups."
      metadata             = local._pb_meta
      parameters = {
        effect               = local._pb_effect_param
        exemptResourceGroups = local._pb_exempt_rgs_param
      }
      policy_rule = {
        if = { allOf = [
          local._pb_rg_not_exempt,
          { field = "type", equals = "Microsoft.Storage/storageAccounts" },
          { anyOf = [
            { field = "Microsoft.Storage/storageAccounts/supportsHttpsTrafficOnly", notEquals = true },
            { field = "Microsoft.Storage/storageAccounts/minimumTlsVersion", notEquals = "TLS1_2" },
            { field = "Microsoft.Storage/storageAccounts/allowBlobPublicAccess", notEquals = false },
          ] },
        ] }
        then = { effect = "[parameters('effect')]" }
      }
    }
    "cmp-deny-public-ip" = {
      display_name         = "Compeer - Restrict public IP creation"
      management_group_key = local.pb_mg_key
      description          = "Audits or denies public IP address resources unless explicitly approved."
      metadata             = local._pb_meta
      parameters           = { effect = local._pb_effect_param }
      policy_rule = {
        if   = { field = "type", equals = "Microsoft.Network/publicIPAddresses" }
        then = { effect = "[parameters('effect')]" }
      }
    }
    "cmp-sql-private-network" = {
      display_name         = "Compeer - Require private SQL network posture"
      management_group_key = local.pb_mg_key
      description          = "Audits or denies Azure SQL servers that allow public network access."
      metadata             = local._pb_meta
      parameters           = { effect = local._pb_effect_param }
      policy_rule = {
        if = { allOf = [
          { field = "type", equals = "Microsoft.Sql/servers" },
          { field = "Microsoft.Sql/servers/publicNetworkAccess", notEquals = "Disabled" },
        ] }
        then = { effect = "[parameters('effect')]" }
      }
    }
  }

  pb_assignments = { for k, v in local.pb_assignments_all : k => v if local.pb_enabled }
  pb_assignments_all = merge(
    {
      "cmp-allowed-locations" = {
        name                    = "cmp-allowed-loc"
        display_name            = "Compeer - Allowed regions"
        management_group_key    = local.pb_mg_key
        policy_definition_key   = "cmp-allowed-locations"
        enforce                 = local.pb_enforce
        not_scopes              = local.pb_not_scopes
        parameters              = { allowedLocations = { value = local.pb_locations }, effect = { value = local.pb_effect } }
        non_compliance_messages = { default = { content = "Deploy resources only in Compeer-approved regions." } }
      }
      "cmp-required-tags" = {
        name                  = "cmp-required-tags"
        display_name          = "Compeer - Required tags"
        management_group_key  = local.pb_mg_key
        policy_definition_key = "cmp-required-tags"
        enforce               = local.pb_enforce
        not_scopes            = local.pb_not_scopes
        parameters            = { requiredTagNames = { value = local.pb_required_tags }, effect = { value = local.pb_effect } }
      }
      "cmp-deny-public-paas" = {
        name                  = "cmp-deny-pub-paas"
        display_name          = "Compeer - Deny public PaaS"
        management_group_key  = local.pb_mg_key
        policy_definition_key = "cmp-deny-public-paas"
        enforce               = local.pb_enforce
        not_scopes            = local.pb_not_scopes
        parameters = {
          effect               = { value = local.pb_effect }
          exemptResourceGroups = { value = local.pb_exempt_rgs }
        }
        non_compliance_messages = { default = { content = "Disable public network access (private endpoint / service endpoint + Deny). Documented exceptions must be in an approved exempt resource group." } }
      }
      "cmp-secure-storage" = {
        name                  = "cmp-secure-storage"
        display_name          = "Compeer - Secure storage"
        management_group_key  = local.pb_mg_key
        policy_definition_key = "cmp-secure-storage"
        enforce               = local.pb_enforce
        not_scopes            = local.pb_not_scopes
        parameters = {
          effect               = { value = local.pb_effect }
          exemptResourceGroups = { value = local.pb_exempt_rgs }
        }
      }
      "cmp-deny-public-ip" = {
        name                  = "cmp-deny-pip"
        display_name          = "Compeer - Restrict public IP"
        management_group_key  = local.pb_mg_key
        policy_definition_key = "cmp-deny-public-ip"
        enforce               = local.pb_enforce
        not_scopes            = local.pb_not_scopes
        parameters            = { effect = { value = local.pb_effect } }
      }
      "cmp-sql-private-network" = {
        name                  = "cmp-sql-private"
        display_name          = "Compeer - Private SQL network"
        management_group_key  = local.pb_mg_key
        policy_definition_key = "cmp-sql-private-network"
        enforce               = local.pb_enforce
        not_scopes            = local.pb_not_scopes
        parameters            = { effect = { value = local.pb_effect } }
      }
    },
    local.pb_assign_mcsb ? {
      "cmp-mcsb" = {
        name                     = "cmp-mcsb"
        display_name             = "Microsoft Cloud Security Benchmark"
        description              = "Baseline security benchmark - Audit."
        management_group_key     = local.pb_mg_key
        policy_set_definition_id = local.pb_mcsb_id
        enforce                  = false
        not_scopes               = local.pb_not_scopes
      }
    } : {}
  )
}
