# PHASE 2 NEW: opt-in platform ownership of private endpoint DNS registration.
# Existing zones are referenced, never created/imported. Existing policy inputs are unchanged.
variable "private_endpoint_dns_policies" {
  description = "Approved, disjoint MG scopes for Key Vault/Blob DNS-registration policies. Empty disables this extension. Zone IDs belong here, not in policy-owned spokes."
  type = map(object({
    management_group_key         = string
    zone_ids                     = map(string)
    approval_reference           = string
    not_scopes                   = optional(list(string), [])
    manage_zone_role_assignments = optional(bool, true)
  }))
  default = {}
  validation {
    condition = alltrue([for key, target in var.private_endpoint_dns_policies :
      can(regex("^[a-z][a-z0-9-]{0,39}$", key)) && length(trimspace(target.approval_reference)) > 0 &&
      length(target.zone_ids) > 0 &&
      length(setsubtract(toset(keys(target.zone_ids)), toset(["key_vault", "storage_blob"]))) == 0 &&
      alltrue([for service, id in target.zone_ids :
        can(regex("(?i)^/subscriptions/[0-9a-f]{8}(-[0-9a-f]{4}){3}-[0-9a-f]{12}/resourceGroups/[^/]+/providers/Microsoft\\.Network/privateDnsZones/${service == "key_vault" ? "privatelink\\.vaultcore\\.azure\\.net" : "privatelink\\.blob\\.core\\.windows\\.net"}$", id))
      ])
    ])
    error_message = "DNS targets require stable keys, approval reference and full existing Key Vault/Blob zone IDs under key_vault/storage_blob."
  }
}

variable "private_endpoint_dns_backfill_approved" {
  description = "Explicit approval for DNS remediation tasks only after the assignments and zone permissions already exist. Do not enable during initial identity bootstrap."
  type        = bool
  default     = false
}

locals {
  # Microsoft Azure/azure-policy definitions, verified against their published JSON.
  private_endpoint_dns_builtins = {
    key_vault    = "/providers/Microsoft.Authorization/policyDefinitions/ac673a9a-f77d-4846-b2d8-a57f8e1c01d4"
    storage_blob = "/providers/Microsoft.Authorization/policyDefinitions/75973700-529f-4de2-b794-fb9b6781b6b0"
  }
  private_endpoint_dns_entries = merge([for target_key, target in var.private_endpoint_dns_policies : {
    for service, zone_id in target.zone_ids : "dns-${substr(sha256(target_key), 0, 8)}-${service == "key_vault" ? "kv" : "blob"}" => {
      target_key                   = target_key
      service                      = service
      zone_id                      = zone_id
      management_group_key         = target.management_group_key
      not_scopes                   = target.not_scopes
      manage_zone_role_assignments = target.manage_zone_role_assignments
      approval_reference           = target.approval_reference
    }
  }]...)
  private_endpoint_dns_dine_assignments = {
    for key, entry in local.private_endpoint_dns_entries : key => {
      policy_definition_id = lookup(local.private_endpoint_dns_builtins, entry.service, "invalid")
      management_group_key = entry.management_group_key
      not_scopes           = entry.not_scopes
      display_name         = "Compeer private endpoint DNS: ${entry.target_key}/${entry.service}"
      description          = "Platform-owned DNS registration approved under ${entry.approval_reference}. Existing DNS zones retain their owner."
      role_definition_ids  = ["/providers/Microsoft.Authorization/roleDefinitions/4d97b98b-1d4f-4787-a291-c67834d212e7"]
      parameters = {
        effect           = { value = "DeployIfNotExists" }
        privateDnsZoneId = { value = entry.zone_id }
      }
    }
  }
}

resource "terraform_data" "private_endpoint_dns_contract" {
  count = length(var.private_endpoint_dns_policies) > 0 ? 1 : 0
  lifecycle {
    precondition {
      condition     = var.private_endpoint_dns_backfill_approved || alltrue([for task in values(try(var.policy.remediation.tasks, {})) : !contains(keys(local.private_endpoint_dns_entries), task.assignment_key)])
      error_message = "DNS backfill requires private_endpoint_dns_backfill_approved=true after policy identities and zone RBAC are already deployed. Do not start tasks in the initial bootstrap apply."
    }
    precondition {
      condition     = local.enabled && alltrue([for target in values(var.private_endpoint_dns_policies) : contains(keys(local.management_group_ids), target.management_group_key)])
      error_message = "Enable the existing platform-policy owner and resolve every DNS policy management_group_key before deployment."
    }
    precondition {
      condition     = length(distinct([for target in values(var.private_endpoint_dns_policies) : target.management_group_key])) == length(var.private_endpoint_dns_policies)
      error_message = "Use one DNS-registration target per MG; ancestor/descendant scopes must also be disjoint through approved exclusions."
    }
    precondition {
      condition     = length(setintersection(toset(keys(local.private_endpoint_dns_dine_assignments)), toset(keys(try(var.policy.remediation.dine_assignments, {}))))) == 0
      error_message = "A DNS assignment key collides with a manual remediation assignment."
    }
  }
}

# Full ARM scopes allow cross-subscription grants without a DNS provider alias.
# If the legacy zone owner grants these externally, set manage_zone_role_assignments=false.
resource "azurerm_role_assignment" "private_endpoint_dns_zone" {
  for_each                         = { for key, entry in local.private_endpoint_dns_entries : key => entry if local.enabled && entry.manage_zone_role_assignments }
  scope                            = each.value.zone_id
  role_definition_name             = "Private DNS Zone Contributor"
  principal_id                     = module.policy[0].remediation_assignment_principal_ids[each.key]
  principal_type                   = "ServicePrincipal"
  skip_service_principal_aad_check = true
  depends_on                       = [terraform_data.private_endpoint_dns_contract]
}

output "private_endpoint_dns_registration" {
  description = "Approved DNS catalog and policy principals for platform-owned registration. Not proof of live readiness; existing endpoint backfill uses explicit remediation.tasks."
  value = { for key, entry in local.private_endpoint_dns_entries : "${entry.target_key}.${entry.service}" => {
    zone_id                 = entry.zone_id
    assignment_key          = key
    assignment_id           = try(module.policy[0].remediation_assignment_ids[key], null)
    principal_id            = try(module.policy[0].remediation_assignment_principal_ids[key], null)
    zone_role_assignment_id = try(azurerm_role_assignment.private_endpoint_dns_zone[key].id, null)
    zone_permissions_owner  = entry.manage_zone_role_assignments ? "platform-policy" : "existing-zone-owner"
  } }
}
