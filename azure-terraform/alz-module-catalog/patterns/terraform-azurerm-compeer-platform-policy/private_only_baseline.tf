# =============================================================================
# Guardrail bundle: private-only connectivity
#
# Compeer forces all inbound traffic through Cloudflare Tunnels and requires
# private connectivity to Azure resources. There is no single Azure "setting"
# for this - it is a policy initiative:
#
#   1. deny-public-ip-address  - block creation of Public IP addresses outside
#      an allow-list of resource groups (Palo untrust, Bastion, VPN/ER gateway,
#      any AppGW that must stay internet-facing).
#   2. deny-nic-public-ip      - block NICs that carry a Public IP.
#   3. (optional) a set of built-in "disable public network access" policies for
#      PaaS services (storage, key vault, app service, SQL, ...). These are
#      OFF by default because the built-in GUIDs must be verified against the
#      tenant - see README, "Built-in companion policies".
#
# Enable via var.private_only_connectivity. Everything here merges into the
# pattern's existing custom_policy_definitions / custom_policy_set_definitions /
# management_group_policy_assignments maps, so it behaves exactly like any other
# hand-authored policy.
# =============================================================================

locals {
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
}
