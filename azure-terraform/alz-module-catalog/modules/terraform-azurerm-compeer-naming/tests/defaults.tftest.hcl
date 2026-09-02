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

run "token_dependent_names" {
  command = apply

  variables {
    region      = "centralus"
    environment = "prod"
    purpose     = "hub"
    destination = "default"
    resource    = "fw"
    appcode     = "platform"
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
    condition     = output.key_vault == "platform-cus-prod-vault"
    error_message = "key vault pattern <appcode>-<region>-<env>-vault"
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

run "entra_and_policy_casing" {
  command = apply

  variables {
    region       = "centralus"
    environment  = "prod"
    domain       = "security"
    purpose      = "baseline"
    policy       = "security"
    scope        = "prod"
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
    region      = "centralus"
    environment = "prod"
    appcode     = "verylongapplicationcode"
  }

  expect_failures = [output.key_vault]
}
