locals {
  management_group_scope_ids = {
    for key, value in var.management_group_ids : key => (
      startswith(value, "/providers/Microsoft.Management/managementGroups/") ? value : "/providers/Microsoft.Management/managementGroups/${value}"
    )
  }

  # -----------------------------------------------------------------------
  # Resolve management_group_key -> a concrete management_group_id and drop
  # the key before handing entries to module.policy - that module has no
  # concept of this pattern's MG catalog (see
  # modules/terraform-azurerm-compeer-policy's README "Boundary" section).
  # policy_definition_key / policy_set_definition_key / policy_assignment_key
  # are left untouched: those resolve against sibling definitions/initiatives
  # /assignments the module itself creates in the same call, so the module
  # keeps doing that resolution internally. module.policy's variables are
  # typed `any` (not a strict object schema) specifically so this
  # filter-then-merge works: real policy parameters/policy_rule/metadata have
  # a genuinely different attribute key set per policy, and only `any` avoids
  # a "cannot find a common base type" module-boundary error across such a
  # map.
  #
  # remediation.tf's DINE assignments (local.rem_assignments) fold into the
  # same management_group_assignments map here, keyed "rem-<key>" - they're
  # just management-group policy assignments with a SystemAssigned identity
  # and LAW-parameter-injection business logic that remediation.tf still
  # owns; the resource mechanics live in module.policy like everything else.
  # -----------------------------------------------------------------------

  policy_definitions_input = {
    for k, v in merge(var.custom_policy_definitions, local.poc_definitions) : k => merge(
      { for ik, iv in v : ik => iv if ik != "management_group_key" && ik != "management_group_id" },
      { management_group_id = coalesce(try(v.management_group_id, null), try(local.management_group_scope_ids[v.management_group_key], null)) }
    )
  }

  policy_set_definitions_input = {
    for k, v in merge(var.custom_policy_set_definitions, local.poc_set_definitions) : k => merge(
      { for ik, iv in v : ik => iv if ik != "management_group_key" && ik != "management_group_id" && ik != "domain" },
      {
        name                = coalesce(try(v.name, null), module.naming_initiative[k].policy_initiative, k)
        management_group_id = coalesce(try(v.management_group_id, null), try(local.management_group_scope_ids[v.management_group_key], null))
      }
    )
  }

  management_group_policy_assignments_input = merge(
    {
      for k, v in merge(var.management_group_policy_assignments, local.poc_assignments) : k => merge(
        { for ik, iv in v : ik => iv if ik != "management_group_key" && ik != "management_group_id" && ik != "location" && ik != "policy" && ik != "policy_scope" },
        {
          name                = coalesce(try(v.name, null), module.naming_assignment[k].policy_assignment, k)
          management_group_id = coalesce(try(v.management_group_id, null), try(local.management_group_scope_ids[v.management_group_key], null))
          location            = try(v.identity, null) == null ? null : try(v.location, var.policy_assignment_location)
        }
      )
    },
    local.remediation_assignments_input
  )

  subscription_policy_assignments_input = {
    for k, v in var.subscription_policy_assignments : k => merge(
      { for ik, iv in v : ik => iv if ik != "location" && ik != "policy" && ik != "policy_scope" },
      {
        name     = coalesce(try(v.name, null), module.naming_assignment[k].policy_assignment, k)
        location = try(v.identity, null) == null ? null : try(v.location, var.policy_assignment_location)
      }
    )
  }

  # Resource-group assignments pass through unchanged. Exemptions resolve an
  # optional management-group catalog key before reaching the policy module.
  resource_group_policy_assignments_input = var.resource_group_policy_assignments

  # policy_assignment_key resolves against module.policy's OWN merged
  # assignment map (all 3 scopes, including remediation's "rem-<key>"
  # entries) - that resolution stays inside the module, since the referenced
  # ID is a value the module itself computes. management_group_key here is
  # the one thing that DOES need resolving here, since the MG catalog is
  # external to the module.
  policy_exemptions_input = {
    for k, v in var.policy_exemptions : k => merge(
      { for ik, iv in v : ik => iv if ik != "management_group_key" && ik != "management_group_id" },
      { management_group_id = coalesce(try(v.management_group_id, null), try(local.management_group_scope_ids[v.management_group_key], null)) }
    )
  }

  # Private-only connectivity is an optional initiative composed from custom
  # Public IP controls and tenant-verified built-in companion policies.
  poc                 = var.private_only_connectivity
  poc_enabled         = try(local.poc.enabled, false)
  poc_mg_key          = try(local.poc.management_group_key, null)
  poc_mg_id           = try(local.poc.management_group_id, null)
  poc_effect          = try(local.poc.effect, "Audit") # Audit first, then flip to Deny
  poc_allowed_rgs     = try(local.poc.allowed_public_ip_resource_group_names, [])
  poc_not_scopes      = try(local.poc.not_scopes, [])
  poc_builtin_ids     = try(local.poc.builtin_policy_definition_ids, {})
  poc_include_builtin = try(local.poc.include_builtin_baseline, false)

  poc_definitions = { for k, v in local.poc_definitions_all : k => v if local.poc_enabled }
  poc_definitions_all = {
    "deny-public-ip-address" = {
      display_name         = "Compeer - Public IP addresses are not allowed outside approved resource groups"
      mode                 = "All"
      management_group_key = local.poc_mg_key
      management_group_id  = local.poc_mg_id
      description          = "Denies creation of Public IP addresses except in resource groups on the approved edge allow-list."
      parameters = {
        effect = {
          type          = "String"
          allowedValues = ["Audit", "Deny", "Disabled"]
          defaultValue  = "Audit"
          metadata      = { displayName = "Effect" }
        }
        allowedResourceGroupNames = {
          type         = "Array"
          defaultValue = []
          metadata     = { displayName = "Resource groups permitted to hold Public IPs" }
        }
      }
      policy_rule = {
        if = {
          allOf = [
            { field = "type", equals = "Microsoft.Network/publicIPAddresses" },
            { not = { field = "resourceGroup", in = "[parameters('allowedResourceGroupNames')]" } }
          ]
        }
        then = { effect = "[parameters('effect')]" }
      }
    }

    "deny-nic-public-ip" = {
      display_name         = "Compeer - Network interfaces must not have a Public IP"
      mode                 = "All"
      management_group_key = local.poc_mg_key
      management_group_id  = local.poc_mg_id
      description          = "Denies network interfaces that attach a Public IP address."
      parameters = {
        effect = {
          type          = "String"
          allowedValues = ["Audit", "Deny", "Disabled"]
          defaultValue  = "Audit"
          metadata      = { displayName = "Effect" }
        }
      }
      policy_rule = {
        if = {
          allOf = [
            { field = "type", equals = "Microsoft.Network/networkInterfaces" },
            { field = "Microsoft.Network/networkInterfaces/ipConfigurations[*].publicIpAddress.id", exists = "true" }
          ]
        }
        then = { effect = "[parameters('effect')]" }
      }
    }
  }

  # Custom-only initiative. Built-in companions are referenced by full ID and are
  # opt-in (see README) because their GUIDs are tenant-verifiable, not ours.
  poc_builtin_refs = {
    for ref_key, builtin_id in local.poc_builtin_ids : ref_key => {
      policy_definition_id = builtin_id
      reference_id         = ref_key
      parameter_values     = {}
    }
    if local.poc_include_builtin
  }

  poc_set_definitions = { for k, v in local.poc_set_definitions_all : k => v if local.poc_enabled }
  poc_set_definitions_all = {
    "compeer-private-only-connectivity" = {
      display_name         = "Compeer - Private-only connectivity baseline"
      management_group_key = local.poc_mg_key
      management_group_id  = local.poc_mg_id
      description          = "No public IPs outside the approved edge; PaaS public network access disabled."
      parameters = {
        effect = {
          type          = "String"
          allowedValues = ["Audit", "Deny", "Disabled"]
          defaultValue  = "Audit"
          metadata      = { displayName = "Effect for the custom Public IP rules" }
        }
        allowedResourceGroupNames = {
          type         = "Array"
          defaultValue = []
          metadata     = { displayName = "Resource groups permitted to hold Public IPs" }
        }
      }
      policy_definition_references = merge(
        {
          "deny-public-ip-address" = {
            policy_definition_key = "deny-public-ip-address"
            reference_id          = "denyPublicIpAddress"
            parameter_values = {
              effect                    = { value = "[parameters('effect')]" }
              allowedResourceGroupNames = { value = "[parameters('allowedResourceGroupNames')]" }
            }
          }
          "deny-nic-public-ip" = {
            policy_definition_key = "deny-nic-public-ip"
            reference_id          = "denyNicPublicIp"
            parameter_values = {
              effect = { value = "[parameters('effect')]" }
            }
          }
        },
        local.poc_builtin_refs
      )
    }
  }

  poc_assignments = { for k, v in local.poc_assignments_all : k => v if local.poc_enabled }
  poc_assignments_all = {
    "compeer-private-only-connectivity" = {
      name                      = "private-only-conn"
      display_name              = "Compeer - Private-only connectivity baseline"
      description               = "Forces private connectivity; inbound via Cloudflare Tunnels only."
      management_group_key      = local.poc_mg_key
      management_group_id       = local.poc_mg_id
      policy_set_definition_key = "compeer-private-only-connectivity"
      enforce                   = try(local.poc.enforce, true)
      not_scopes                = local.poc_not_scopes
      parameters = {
        effect                    = { value = local.poc_effect }
        allowedResourceGroupNames = { value = local.poc_allowed_rgs }
      }
      non_compliance_messages = {
        default = { content = "This resource must use private connectivity. Public IPs are only allowed in approved edge resource groups (Palo Alto, Bastion, VPN/ER gateway)." }
      }
    }
  }

  # DINE/Modify assignments use a system-assigned identity and can inject the
  # platform Log Analytics workspace into policy parameters.
  rem          = var.remediation
  rem_enabled  = try(local.rem.enabled, false)
  rem_mg_key   = try(local.rem.management_group_key, null)
  rem_location = try(local.rem.location, var.policy_assignment_location)
  rem_law_id   = try(local.rem.log_analytics_workspace_id, null)
  rem_identity = { type = "SystemAssigned" }

  # Each entry: { policy_definition_id (built-in, full ID), parameters = {},
  #               inject_law = optional(bool) - adds logAnalytics/workspaceId param }
  rem_assignments = { for k, v in try(local.rem.dine_assignments, {}) : k => v if local.rem_enabled }

  # Keyed "rem-<key>" so it can merge safely with hand-authored /
  # private-only-connectivity assignments in the same map without colliding.
  remediation_assignments_input = {
    for k, v in local.rem_assignments : "rem-${k}" => {
      name                 = substr("rem-${k}", 0, 24)
      management_group_id  = try(local.management_group_scope_ids[local.rem_mg_key], null)
      policy_definition_id = v.policy_definition_id
      display_name         = try(v.display_name, "Remediation - ${k}")
      description          = try(v.description, "DeployIfNotExists remediation managed by platform-policy.")
      enforce              = try(v.enforce, true)
      location             = local.rem_location
      not_scopes           = try(v.not_scopes, null)
      identity             = local.rem_identity
      parameters = merge(
        try(v.parameters, {}),
        try(v.inject_law, false) && local.rem_law_id != null ? {
          logAnalytics = { value = local.rem_law_id }
        } : {},
      )
    }
  }
}
