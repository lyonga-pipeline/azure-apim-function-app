check "platform_scope_needs_component_for_keyed_disc_abbr_resources" {
  assert {
    condition = !(
      local.scope == "platform" &&
      local.component == null &&
      (length(var.key_vault_keys) > 0 || length(var.storage_account_keys) > 0 || length(var.user_assigned_identity_keys) > 0)
    )
    error_message = "scope = \"platform\" with no `component` set falls back to the generic \"platform\" discriminator (disc_abbr \"plat\") for key_vault_names/storage_account_names/user_assigned_identity_names - two different platform roots that both omit `component` would compute the identical name. Set `component` (e.g. \"management\", \"connectivity\") on this module call."
  }
}

check "workload_scope_needs_domain" {
  assert {
    condition     = !(local.scope == "workload" && local.domain == null)
    error_message = "scope = \"workload\" requires `domain` (e.g. \"internal-apps\") - without it, `stem`, `resource_group`, `workload_vnet`, and every other workload-scoped output cannot be computed. (Omitting `domain` under scope = \"workload\" also fails during evaluation with an internal 'null value in a string template' error from `local.stem` - this check exists to give that same failure a clear, actionable message instead.)"
  }
}

check "keyed_names_have_no_case_collisions" {
  assert {
    condition = alltrue([
      for resource_type, names in local.keyed : length(distinct(values(names))) == length(values(names))
    ])
    error_message = "two or more keys for the same keyed resource type normalise to the identical Azure name (e.g. \"Primary\" and \"primary\" both lower-case into the same `<key>` token). Colliding resource type(s): ${jsonencode({ for resource_type, names in local.keyed : resource_type => names if length(distinct(values(names))) != length(values(names)) })}. Rename one of the keys so they differ after lower-casing."
  }
}

check "tokens_use_supported_characters" {
  assert {
    condition = alltrue(concat(
      [
        for token in [var.component, var.domain, var.purpose, var.destination, var.resource, var.name, var.policy, var.policy_scope] :
        token == null || can(regex("^[a-zA-Z0-9]+(?:-[a-zA-Z0-9]+)*$", trimspace(token)))
      ],
      flatten([
        for keys in [
          var.key_vault_keys,
          var.storage_account_keys,
          var.user_assigned_identity_keys,
          var.nsg_keys,
          var.route_table_keys,
          var.public_ip_keys,
          var.private_endpoint_keys,
          var.network_interface_keys,
          var.load_balancer_keys,
          var.virtual_machine_keys,
          var.disk_keys,
          var.recovery_services_vault_keys,
          var.function_app_keys,
          var.subnet_keys,
        ] : [for key in keys : can(regex("^[a-zA-Z0-9]+(?:[-_][a-zA-Z0-9]+)*$", trimspace(key)))]
      ])
    ))
    error_message = "Naming tokens must use alphanumeric segments separated by single hyphens. Stable resource keys may use single hyphens or underscores; underscores are rendered as hyphens in Azure names."
  }
}

check "function_app_keys_are_instance_numbers" {
  assert {
    condition     = alltrue([for key in var.function_app_keys : try(tonumber(key) >= 1 && tonumber(key) <= 99, false)])
    error_message = "function_app_keys must be instance numbers from 1 to 99; names render them as two digits."
  }
}
