# =============================================================================
# Cross-input checks that a single variable's own `validation` block can't
# express (a variable can only validate itself). These catch identity
# combinations that would otherwise either fail later with a cryptic internal
# interpolation error, or - worse - silently succeed with a generic,
# collision-prone name.
# =============================================================================

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

# A caller passing two keys that only differ by case (e.g. "Primary" and
# "primary") gets two DISTINCT map entries whose rendered names are IDENTICAL,
# since every keyed pattern lower-cases the key but not the map key itself.
# That's a real Azure-side collision (two resources computing the same name)
# hiding behind two different `for_each` keys, not a Terraform error - check
# every keyed collection for it in one place rather than repeating the same
# `distinct(values(...))` assertion in all thirteen keyed outputs.
check "keyed_names_have_no_case_collisions" {
  assert {
    condition = alltrue([
      for resource_type, names in local.keyed : length(distinct(values(names))) == length(values(names))
    ])
    error_message = "two or more keys for the same keyed resource type normalise to the identical Azure name (e.g. \"Primary\" and \"primary\" both lower-case into the same `<key>` token). Colliding resource type(s): ${jsonencode({ for resource_type, names in local.keyed : resource_type => names if length(distinct(values(names))) != length(values(names)) })}. Rename one of the keys so they differ after lower-casing."
  }
}
