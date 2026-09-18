# Pure module - no providers. Assert the Appendix F patterns exactly.

run "core_platform_names_region_and_env_only" {
  command = apply

  variables {
    region      = "centralus"
    environment = "prod"
  }

  assert {
    condition     = output.region_short == "cus"
    error_message = "region short code"
  }
  assert {
    condition     = output.hub_vnet == "platform-cus-prod-hub-vnet"
    error_message = "hub vnet name"
  }
  assert {
    condition     = output.shared_vnet == "platform-cus-prod-shared-vnet"
    error_message = "shared vnet name"
  }
  assert {
    condition     = output.platform_resource_group == "platform-cus-prod-rg"
    error_message = "platform RG name"
  }
  assert {
    condition     = output.firewall_vm == "platform-cus-prod-fw-01"
    error_message = "firewall VM name (default instance 1 -> 01)"
  }
  assert {
    condition     = output.firewall_ilb == "platform-cus-prod-fw-ilb"
    error_message = "firewall ILB name"
  }
  assert {
    condition     = output.expressroute_gateway == "platform-cus-prod-ergw" && output.vpn_gateway == "platform-cus-prod-vpngw"
    error_message = "gateway names"
  }
  assert {
    condition     = output.log_analytics_workspace == "cus-prod-loganalytics-workspace"
    error_message = "law name"
  }
  assert {
    condition     = output.monitor_workspace == "platform-cus-prod-monitor"
    error_message = "monitor workspace name"
  }
  assert {
    condition     = output.recovery_services_vault == "platform-cus-prod-rsv"
    error_message = "rsv name"
  }
  assert {
    condition     = output.subscription_platform == "sub-platform-prod-cus" && output.subscription_connectivity == "sub-connectivity-prod-cus"
    error_message = "subscription names"
  }
  assert {
    condition     = output.mg_enterprise == "compeer-enterprise-mg" && output.mg_platform == "platform-mg" && output.mg_workloads == "workloads-mg"
    error_message = "fixed MG names"
  }
  # token-dependent names are null until their tokens are supplied
  assert {
    condition     = output.key_vault == null && output.subnet == null && output.nsg == null && output.route_table == null && output.public_ip == null
    error_message = "token-dependent names should be null without their tokens"
  }
  assert {
    condition     = output.subscription_workload == null && output.mg_workload_domain == null && output.entra_security_group == null && output.policy_assignment == null
    error_message = "domain/entra/policy names should be null without their tokens"
  }
}

run "accepts_existing_lz_environment_aliases" {
  command = apply

  variables {
    region      = "centralus"
    environment = "np2"
  }

  assert {
    condition     = output.hub_vnet == "platform-cus-np2-hub-vnet"
    error_message = "np1, np2, and np3 must be accepted consistently with the tagging module"
  }
}

run "rejects_ambiguous_np_environment" {
  command = plan

  variables {
    region      = "centralus"
    environment = "np"
  }

  expect_failures = [var.environment]
}

run "approved_abbreviation_overrides_fallback" {
  command = apply

  variables {
    region         = "centralus"
    environment    = "prod"
    component      = "custom-platform-component"
    abbreviation   = "cpc"
    key_vault_keys = ["primary"]
  }

  assert {
    condition     = output.key_vault_names["primary"] == "cpc-cus-prod-primary-kv"
    error_message = "an approved abbreviation must control constrained resource prefixes"
  }
}

run "rejects_malformed_resource_key" {
  command = plan

  variables {
    region      = "centralus"
    environment = "prod"
    component   = "management"
    nsg_keys    = ["bad key"]
  }

  expect_failures = [check.tokens_use_supported_characters]
}

run "normalizes_underscore_resource_keys" {
  command = apply

  variables {
    region                 = "centralus"
    environment            = "prod"
    component              = "palo-alto"
    network_interface_keys = ["fw1_mgmt"]
  }

  assert {
    condition     = output.network_interface_names["fw1_mgmt"] == "cus-prod-fw1-mgmt-nic"
    error_message = "stable underscore keys must render Azure-compatible hyphenated names"
  }
}

run "token_dependent_names" {
  command = apply

  variables {
    region      = "centralus"
    environment = "prod"
    purpose     = "hub"
    destination = "default"
    resource    = "fw"
    component   = "platform"
    name        = "apim"
    domain      = "internal-apps"
    instance    = 2
  }

  assert {
    condition     = output.subnet == "prod-hub-subnet"
    error_message = "subnet pattern <env>-<purpose>-subnet"
  }
  assert {
    condition     = output.nsg == "cus-prod-hub-nsg"
    error_message = "nsg pattern <region>-<env>-<purpose>-nsg"
  }
  assert {
    condition     = output.route_table == "cus-prod-default-rt"
    error_message = "route table pattern <region>-<env>-<destination>-rt"
  }
  assert {
    condition     = output.public_ip == "cus-prod-fw-pip"
    error_message = "public ip pattern <region>-<env>-<resource>-pip"
  }
  assert {
    condition     = output.key_vault == "plat-cus-prod-vault"
    error_message = "key vault pattern <disc_abbr>-<region>-<env>-vault for platform scope (component \"platform\" abbreviates to \"plat\" in the abbreviation map)"
  }
  assert {
    condition     = output.subscription_workload == "sub-workload-apim-prod-cus"
    error_message = "workload subscription pattern"
  }
  assert {
    condition     = output.mg_workload_domain == "internal-apps-mg" && output.mg_workload_domain_environment == "internal-apps-prod-mg"
    error_message = "workload-domain MG patterns"
  }
  assert {
    condition     = output.private_dns_zone == "internal-apps-pdns"
    error_message = "private dns zone pattern <domain>-pdns"
  }
  assert {
    condition     = output.firewall_vm == "platform-cus-prod-fw-02" && output.cloudflare_connector == "platform-cus-prod-cf-connector-02"
    error_message = "instance 2 -> 02"
  }
}

run "adapted_names" {
  command = apply

  variables {
    region      = "centralus"
    environment = "prod"
    purpose     = "connectivity"
    domain      = "internal-apps"
    resource    = "fw"
    instance    = 3
  }

  assert {
    condition     = output.resource_group == "platform-cus-prod-connectivity-rg"
    error_message = "per-capability RG pattern"
  }
  assert {
    condition     = output.workload_resource_group == "internal-apps-prod-rg"
    error_message = "workload RG pattern"
  }
  assert {
    condition     = output.workload_vnet == "internal-apps-cus-prod-vnet"
    error_message = "workload vnet pattern"
  }
  assert {
    condition     = output.mg == "internal-apps-mg" && output.mg_environment == "internal-apps-prod-mg"
    error_message = "generic mg patterns"
  }
  assert {
    condition     = output.automation_account == "platform-cus-prod-aa" && output.action_group == "platform-cus-prod-ag"
    error_message = "automation / action group adapted patterns"
  }
  assert {
    condition     = output.bastion == "platform-cus-prod-bas" && output.nat_gateway == "platform-cus-prod-natgw" && output.ddos_protection_plan == "platform-cus-prod-ddos"
    error_message = "hub service adapted patterns"
  }
  assert {
    condition     = output.domain_controller_vm == "platform-cus-prod-dc-03"
    error_message = "DC VM adapted pattern (instance 3 -> 03)"
  }
  assert {
    condition     = output.network_interface == "cus-prod-fw-nic" && output.private_endpoint == "cus-prod-fw-pe"
    error_message = "nic / pe adapted patterns"
  }
  assert {
    condition     = output.subscription_scoped == "sub-connectivity-prod-cus"
    error_message = "scoped subscription adapted pattern"
  }
  assert {
    condition     = output.storage_account == "stconnectivitycusprod" && length(output.storage_account) <= 24
    error_message = "storage account no-dash <=24"
  }
  assert {
    condition     = output.user_assigned_identity == "connectivity-cus-prod-id"
    error_message = "user-assigned identity adapted pattern"
  }
  assert {
    condition     = output.load_balancer == "platform-cus-prod-connectivity-ilb"
    error_message = "load balancer adapted pattern"
  }
}

run "platform_root_identity_and_keyed_names" {
  command = apply

  variables {
    region      = "centralus"
    environment = "prod"
    scope       = "platform"
    component   = "management"

    key_vault_keys               = ["primary", "secrets"]
    storage_account_keys         = ["audit", "diag"]
    user_assigned_identity_keys  = ["automation"]
    nsg_keys                     = ["palo-mgmt", "connectors"]
    recovery_services_vault_keys = ["platform"]
  }

  assert {
    condition     = output.resource_group == "platform-cus-prod-management-rg"
    error_message = "platform component RG"
  }
  assert {
    condition     = output.discriminator == "management"
    error_message = "discriminator resolves to component"
  }
  assert {
    condition     = output.key_vault_names["primary"] == "mgmt-cus-prod-primary-kv" && output.key_vault_names["secrets"] == "mgmt-cus-prod-secrets-kv"
    error_message = "keyed key-vault names (abbreviated component)"
  }
  assert {
    condition     = output.storage_account_names["audit"] == "stmgmtauditcusprod" && length(output.storage_account_names["audit"]) <= 24
    error_message = "keyed storage-account names (no dash, <=24)"
  }
  assert {
    condition     = output.user_assigned_identity_names["automation"] == "mgmt-cus-prod-automation-id"
    error_message = "keyed user-assigned-identity names"
  }
  assert {
    condition     = output.nsg_names["palo-mgmt"] == "cus-prod-palo-mgmt-nsg"
    error_message = "keyed NSG names"
  }
  assert {
    condition     = output.recovery_services_vault_names["platform"] == "platform-cus-prod-platform-rsv"
    error_message = "keyed RSV names"
  }
}

run "workload_root_identity" {
  command = apply

  variables {
    region      = "centralus"
    environment = "prod"
    scope       = "workload"
    domain      = "internal-apps"
    appcode     = "orders"

    key_vault_keys       = ["app", "sig"]
    storage_account_keys = ["uploads"]
  }

  assert {
    condition     = output.resource_group == "internal-apps-orders-cus-prod-rg"
    error_message = "workload RG with appcode"
  }
  assert {
    condition     = output.discriminator == "orders"
    error_message = "workload discriminator resolves to appcode"
  }
  assert {
    condition     = output.key_vault_names["app"] == "orders-cus-prod-app-kv"
    error_message = "workload keyed KV names"
  }
  assert {
    condition     = output.key_vault == "orders-cus-prod-vault"
    error_message = "singular key vault leads with appcode for workload scope"
  }
  assert {
    condition     = length(output.storage_account_names["uploads"]) <= 24 && can(regex("^[a-z0-9]+$", output.storage_account_names["uploads"]))
    error_message = "workload keyed storage names <=24, alphanumeric"
  }
}

run "workload_root_no_appcode" {
  command = apply

  variables {
    region      = "centralus"
    environment = "prod"
    scope       = "workload"
    domain      = "internal-apps"
  }

  assert {
    condition     = output.resource_group == "internal-apps-cus-prod-rg"
    error_message = "workload RG without appcode"
  }
}

run "platform_scope_key_vault_leads_with_component_abbreviation" {
  command = apply

  variables {
    region      = "centralus"
    environment = "prod"
    scope       = "platform"
    component   = "identity"
  }

  assert {
    condition     = output.key_vault == "id-cus-prod-vault"
    error_message = "singular key vault leads with disc_abbr (identity -> id) for platform scope, not the literal word platform - this is the real platform-identity pattern's shape, and matches the SAME token keyed key_vault_names already uses for platform scope rather than the raw, unbudgeted component word (management-cus-prod-vault would be 25 chars and overflow the 24-char limit)"
  }
}

run "platform_scope_key_vault_needs_component_no_silent_platform_fallback" {
  command = apply

  variables {
    region      = "centralus"
    environment = "prod"
    scope       = "platform"
  }

  assert {
    condition     = output.key_vault == null
    error_message = "platform scope without component must stay null, not silently default to the literal word 'platform' - a platform root must pass component explicitly, exactly as a workload root must pass appcode"
  }
}

run "storage_uniqueness_suffix" {
  command = apply

  variables {
    region               = "centralus"
    environment          = "prod"
    component            = "management"
    storage_account_keys = ["audit"]
    storage_uniqueness   = "00000000-0000-0000-0000-000000000000"
  }

  assert {
    condition     = length(output.storage_account_names["audit"]) <= 24 && output.storage_account_names["audit"] != "stmgmtauditcusprod"
    error_message = "storage_uniqueness appends a hash suffix"
  }
}

run "rejects_keyed_key_vault_over_24" {
  command = plan

  variables {
    region         = "centralus"
    environment    = "prod"
    component      = "management"
    key_vault_keys = ["this-key-is-far-too-long-to-fit"]
  }

  expect_failures = [output.key_vault_names]
}

run "entra_and_policy_casing" {
  command = apply

  variables {
    region       = "centralus"
    environment  = "prod"
    domain       = "security"
    purpose      = "baseline"
    policy       = "security"
    policy_scope = "prod"
    entra_domain = "plt"
    entra_role   = "Admins"
  }

  assert {
    condition     = output.entra_security_group == "AZ-PLT-Admins"
    error_message = "entra group: domain upper, role case preserved"
  }
  assert {
    condition     = output.policy_initiative == "initiative-security-baseline"
    error_message = "policy initiative pattern"
  }
  assert {
    condition     = output.policy_assignment == "assign-security-prod"
    error_message = "policy assignment pattern"
  }
}

run "normalises_whitespace_and_case" {
  command = apply

  variables {
    region      = "  CentralUS  "
    environment = " PROD "
    purpose     = " Hub "
  }

  assert {
    condition     = output.nsg == "cus-prod-hub-nsg"
    error_message = "inputs should be trimmed + lowercased"
  }
}

run "rejects_unknown_region" {
  command = plan

  variables {
    region      = "marscentral"
    environment = "prod"
  }

  expect_failures = [var.region]
}

run "rejects_unknown_environment" {
  command = plan

  variables {
    region      = "centralus"
    environment = "production"
  }

  expect_failures = [var.environment]
}

run "rejects_key_vault_over_24_chars" {
  command = plan

  variables {
    # appcode is capped at 9 letters (its own validation), so this uses the
    # longest legal appcode plus the longest region/environment combination
    # to still overflow 24 chars: "warehouse-ncus-sandbox-vault" is 28 chars.
    # Explicit workload scope + domain: the singular key_vault output is now
    # scope-aware (appcode for workload, component for platform), and
    # workload scope requires domain regardless of key_vault usage.
    region      = "northcentralus"
    environment = "sandbox"
    scope       = "workload"
    domain      = "internal-apps"
    appcode     = "warehouse"
  }

  expect_failures = [output.key_vault]
}

run "rejects_appcode_over_9_letters" {
  command = plan

  variables {
    region      = "centralus"
    environment = "prod"
    appcode     = "verylongapplicationcode"
  }

  expect_failures = [var.appcode]
}

run "rejects_appcode_with_non_letter_characters" {
  command = plan

  variables {
    region      = "centralus"
    environment = "prod"
    appcode     = "app-01"
  }

  expect_failures = [var.appcode]
}

# ---- Storage-account uniqueness suffix must survive truncation intact -----

run "storage_suffix_survives_truncation" {
  command = apply

  variables {
    region               = "centralus"
    environment          = "prod"
    component            = "management"
    storage_account_keys = ["averyverylongstoragekeyname"]
    storage_uniqueness   = "00000000-0000-0000-0000-000000000000"
  }

  assert {
    condition     = length(output.storage_account_names["averyverylongstoragekeyname"]) == 24
    error_message = "an over-budget storage name should truncate the descriptive base, not overflow past 24"
  }
  assert {
    condition     = substr(output.storage_account_names["averyverylongstoragekeyname"], 20, 4) == substr(md5("00000000-0000-0000-0000-000000000000"), 0, 4)
    error_message = "the 4-char uniqueness suffix must be the LAST 4 characters intact - truncating base+suffix as one string (the pre-fix bug) can chop the suffix off entirely, silently reintroducing a name collision"
  }
}

# ---- Cross-input identity checks --------------------------------------------

run "rejects_platform_scope_without_component_for_keyed_disc_abbr_resources" {
  command = plan

  variables {
    region         = "centralus"
    environment    = "prod"
    key_vault_keys = ["primary"]
  }

  expect_failures = [check.platform_scope_needs_component_for_keyed_disc_abbr_resources]
}

run "platform_scope_without_component_is_fine_for_non_disc_abbr_resources" {
  command = apply

  variables {
    region      = "centralus"
    environment = "prod"
    nsg_keys    = ["web"]
  }

  assert {
    condition     = output.nsg_names["web"] == "cus-prod-web-nsg"
    error_message = "nsg naming doesn't use disc_abbr, so it shouldn't require `component`"
  }
}

run "rejects_workload_scope_without_domain" {
  command = plan

  variables {
    region      = "centralus"
    environment = "prod"
    scope       = "workload"
  }

  expect_failures = [check.workload_scope_needs_domain]
}

run "rejects_case_collision_in_keyed_names" {
  command = plan

  variables {
    region      = "centralus"
    environment = "prod"
    component   = "management"
    nsg_keys    = ["Web", "web"]
  }

  expect_failures = [check.keyed_names_have_no_case_collisions]
}

# ---- New Azure length-constraint preconditions ------------------------------

run "rejects_resource_group_over_90_chars" {
  command = plan

  variables {
    region      = "centralus"
    environment = "prod"
    scope       = "workload"
    # No appcode here on purpose: key_vault also keys off appcode and would
    # fail its own precondition first, masking the resource_group failure
    # this test actually targets. Domain alone, well past 78 chars, is enough
    # to push "<domain>-cus-prod-rg" past Azure's 90-character RG limit.
    domain = "this-is-an-extremely-long-workload-domain-name-that-will-not-possibly-fit-into-the-limit"
  }

  # workload_resource_group shares the same overlong `domain` and fails its
  # own, separate 90-char precondition too - both are correct, expected
  # failures from one bad input, not a masking issue like the key_vault case
  # above.
  expect_failures = [output.resource_group, output.workload_resource_group]
}

run "rejects_network_interface_over_80_chars" {
  command = plan

  variables {
    region      = "centralus"
    environment = "prod"
    resource    = "this-resource-token-is-deliberately-far-too-long-to-fit-into-the-eighty-character-azure-limit-for-network-interfaces"
  }

  # `resource` also drives public_ip and private_endpoint (same ADAPTED
  # token), so all three fail together on one bad input.
  expect_failures = [output.network_interface, output.public_ip, output.private_endpoint]
}

run "rejects_keyed_virtual_machine_over_64_chars" {
  command = plan

  variables {
    region               = "centralus"
    environment          = "prod"
    component            = "management"
    virtual_machine_keys = ["this-virtual-machine-key-is-deliberately-far-too-long-to-fit-into-sixty-four-characters"]
  }

  expect_failures = [output.virtual_machine_names]
}

run "accepts_automation_account_within_bounds" {
  command = apply

  variables {
    region      = "centralus"
    environment = "prod"
  }

  assert {
    condition     = output.automation_account == "platform-cus-prod-aa"
    error_message = "automation_account should always be well within the 6-50 char / starts-with-letter Azure limit given the fixed token set"
  }
}

# ---- Function App: leads with appcode for workload, component for platform -

run "function_app_singular_needs_appcode" {
  command = apply

  variables {
    region      = "centralus"
    environment = "prod"
    appcode     = "orders"
  }

  assert {
    condition     = output.function_app == "orders-cus-prod-func"
    error_message = "function_app should default to <appcode>-<region>-<env>-func"
  }
}

run "function_app_null_without_appcode" {
  command = apply

  variables {
    region      = "centralus"
    environment = "prod"
  }

  assert {
    condition     = output.function_app == null
    error_message = "function_app should be null when appcode is not supplied"
  }
}

run "keyed_function_app_leads_with_appcode_for_workload_scope" {
  command = apply

  variables {
    region            = "centralus"
    environment       = "prod"
    scope             = "workload"
    domain            = "internal-apps"
    appcode           = "orders"
    function_app_keys = ["api", "worker"]
  }

  assert {
    condition     = output.function_app_names["api"] == "orders-cus-prod-api-func" && output.function_app_names["worker"] == "orders-cus-prod-worker-func"
    error_message = "keyed function_app_names should lead with appcode (not domain) for a workload-scoped caller, the same as key_vault_names/storage_account_names"
  }
}

run "keyed_function_app_leads_with_component_for_platform_scope" {
  command = apply

  variables {
    region            = "centralus"
    environment       = "prod"
    component         = "management"
    function_app_keys = ["ops"]
  }

  assert {
    condition     = output.function_app_names["ops"] == "mgmt-cus-prod-ops-func"
    error_message = "keyed function_app_names should lead with the abbreviated component for a platform-scoped caller"
  }
}

run "rejects_function_app_over_60_chars" {
  command = plan

  variables {
    region            = "centralus"
    environment       = "prod"
    appcode           = "warehouse"
    function_app_keys = ["this-key-is-deliberately-far-too-long-to-fit-into-sixty-characters-total"]
  }

  expect_failures = [output.function_app_names]
}
