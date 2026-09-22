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
  # Must track terraform-azurerm-compeer-platform-tags' local.mandatory_keys
  # exactly - this policy audits tags the real tags module actually emits, not
  # the pre-Phase-7 vocabulary (env/bt_owner/tf_workspace/recovery/
  # compliance_boundary) that module was renamed away from.
  pb_required_tags = try(local.pb.required_tag_names, [
    "environment", "application", "appcode", "owner", "source_repo", "created_on",
    "criticality_tier", "data_classification", "lifecycle_state",
    "cost_center", "gl_category", "created_by",
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

  # -----------------------------------------------------------------------
  # Landing-zone baseline initiative (policy set definition).
  #
  # Packages the 6 cmp-* definitions above into one assignable initiative
  # instead of 6 separate management-group policy assignments. This is what
  # var.custom_policy_set_definitions was built for (see the policy module's
  # azurerm_management_group_policy_set_definition.initiative) but had zero
  # callers - policy_baseline is now its first real one, merged in the same
  # way pb_definitions already merges into var.custom_policy_definitions.
  #
  # Each member policy keeps its own parameter wiring via the initiative's
  # own declared parameters (ARM "[parameters('x')]" tokens in
  # parameter_values, same idiom the policy module already uses for
  # MCSB-style initiatives). Today all 6 already share one effect/enforce
  # toggle (var.policy_baseline.effect / .enforce), so bundling them changes
  # zero enforcement behavior - it only replaces 6 assignment objects with 1.
  # A future need for a policy-specific effect is additive from here (expose
  # one more initiative parameter), not a rewrite.
  #
  # Assigning this SAME initiative at more than one management-group scope
  # (e.g. workloads-mg today, a future regulated-apps-mg or per-BU MG) is how
  # this scales without re-declaring the 6 policies per scope: author once
  # here, assign per scope - with independent parameter/not_scopes overrides
  # per assignment - via policy_set_definition_key.
  pb_initiative_key = "compeer-landing-zone-baseline"

  pb_initiative_parameters = {
    effect               = local._pb_effect_param
    exemptResourceGroups = local._pb_exempt_rgs_param
    allowedLocations = {
      type     = "Array"
      metadata = { displayName = "Allowed locations" }
    }
    requiredTagNames = {
      type     = "Array"
      metadata = { displayName = "Required tag names" }
    }
  }

  pb_initiative_references = {
    "cmp-allowed-locations" = {
      policy_definition_key = "cmp-allowed-locations"
      parameter_values = {
        allowedLocations = { value = "[parameters('allowedLocations')]" }
        effect           = { value = "[parameters('effect')]" }
      }
    }
    "cmp-required-tags" = {
      policy_definition_key = "cmp-required-tags"
      parameter_values = {
        requiredTagNames = { value = "[parameters('requiredTagNames')]" }
        effect           = { value = "[parameters('effect')]" }
      }
    }
    "cmp-deny-public-paas" = {
      policy_definition_key = "cmp-deny-public-paas"
      parameter_values = {
        exemptResourceGroups = { value = "[parameters('exemptResourceGroups')]" }
        effect               = { value = "[parameters('effect')]" }
      }
    }
    "cmp-secure-storage" = {
      policy_definition_key = "cmp-secure-storage"
      parameter_values = {
        exemptResourceGroups = { value = "[parameters('exemptResourceGroups')]" }
        effect               = { value = "[parameters('effect')]" }
      }
    }
    "cmp-deny-public-ip" = {
      policy_definition_key = "cmp-deny-public-ip"
      parameter_values      = { effect = { value = "[parameters('effect')]" } }
    }
    "cmp-sql-private-network" = {
      policy_definition_key = "cmp-sql-private-network"
      parameter_values      = { effect = { value = "[parameters('effect')]" } }
    }
  }

  pb_initiative = { for k, v in local.pb_initiative_all : k => v if local.pb_enabled }
  pb_initiative_all = {
    (local.pb_initiative_key) = {
      display_name                 = "Compeer - Landing zone baseline"
      management_group_key         = local.pb_mg_key
      description                  = "Packages the Compeer landing-zone guardrail policies (allowed regions, required tags, deny public PaaS, secure storage, restrict public IP, private SQL) as one assignable initiative."
      metadata                     = local._pb_meta
      parameters                   = local.pb_initiative_parameters
      policy_definition_references = local.pb_initiative_references
    }
  }

  pb_assignments = { for k, v in local.pb_assignments_all : k => v if local.pb_enabled }
  pb_assignments_all = merge(
    {
      "cmp-landing-zone-baseline" = {
        name                      = "cmp-lz-baseline"
        display_name              = "Compeer - Landing zone baseline"
        management_group_key      = local.pb_mg_key
        policy_set_definition_key = local.pb_initiative_key
        enforce                   = local.pb_enforce
        not_scopes                = local.pb_not_scopes
        parameters = {
          effect               = { value = local.pb_effect }
          allowedLocations     = { value = local.pb_locations }
          requiredTagNames     = { value = local.pb_required_tags }
          exemptResourceGroups = { value = local.pb_exempt_rgs }
        }
        non_compliance_messages = {
          default = { content = "Landing-zone baseline guardrail violated - see the policy compliance reason for the specific control (regions, tags, public PaaS access, secure storage, public IP, or private SQL)." }
        }
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
