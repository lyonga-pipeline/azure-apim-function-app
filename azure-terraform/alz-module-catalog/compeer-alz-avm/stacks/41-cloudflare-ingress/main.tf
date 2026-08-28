locals {
  default_operational_contracts = {
    cloudflare_tunnel_connectors = {
      phase                = "Phase 2"
      implementation_state = "provider-gap"
      required_controls    = ["connector subnet", "connector identity", "tunnel token secret handling", "health checks"]
      notes                = "NET-33 tunnel connectors are tracked here until the approved module catalog includes tunnel resources."
    }
    cloudflare_zero_trust_access = {
      phase                = "Phase 2"
      implementation_state = "provider-gap"
      required_controls    = ["Access application", "IdP integration", "service token rotation", "policy review"]
      notes                = "NET-34 is partially covered by zone/ruleset/record modules. Access applications remain an explicit follow-up module."
    }
    ingress_failover_runbook = {
      phase                = "Phase 2"
      implementation_state = "manual-runbook"
      required_controls    = ["Cloudflare to Application Gateway cutover", "DNS TTL validation", "WAF policy parity", "rollback steps"]
      notes                = "NET-40 combines Cloudflare records with Azure App Gateway and an operational failover runbook."
    }
  }
}

module "zone" {
  for_each = var.zones
  source   = "app.terraform.io/Compeer-Financial-Services/compeer-zone/cloudflare"
  version  = "1.0.3"

  account_id           = each.value.account_id
  zone                 = each.value.zone
  zone_jump_start      = try(each.value.zone_jump_start, false)
  zone_paused          = try(each.value.zone_paused, false)
  zone_plan            = try(each.value.zone_plan, null)
  zone_type            = try(each.value.zone_type, "full")
  enable_zone_settings = try(each.value.enable_zone_settings, false)
  settings             = try(each.value.settings, [])
}

module "record" {
  for_each = var.records
  source   = "app.terraform.io/Compeer-Financial-Services/compeer-record-manager/cloudflare"
  version  = "1.0.2"

  zone_id         = coalesce(try(each.value.zone_id, null), try(module.zone[each.value.zone_key].zone_id, null))
  name            = each.value.name
  type            = each.value.type
  value           = try(each.value.value, null)
  data            = try(each.value.data, {})
  ttl             = try(each.value.ttl, null)
  proxied         = try(each.value.proxied, null)
  priority        = try(each.value.priority, null)
  allow_overwrite = try(each.value.allow_overwrite, null)
  comment         = try(each.value.comment, null)
  tags            = try(each.value.tags, [])
  timeouts        = try(each.value.timeouts, {})
}

module "ruleset" {
  for_each = var.rulesets
  source   = "app.terraform.io/Compeer-Financial-Services/compeer-ruleset/cloudflare"
  version  = "1.0.3"

  cloudflare_account_id = try(each.value.cloudflare_account_id, null)
  zone_id               = coalesce(try(each.value.zone_id, null), try(module.zone[each.value.zone_key].zone_id, null))
  ruleset_kind          = each.value.ruleset_kind
  ruleset_name          = each.value.ruleset_name
  ruleset_phase         = each.value.ruleset_phase
  description           = try(each.value.description, null)
  rules                 = try(each.value.rules, [])
}

module "operational_contracts" {
  source  = "app.terraform.io/Compeer-Financial-Services/compeer-operational-contracts/azurerm"
  version = "1.0.0"

  contracts = merge(local.default_operational_contracts, var.operational_contracts)
}
