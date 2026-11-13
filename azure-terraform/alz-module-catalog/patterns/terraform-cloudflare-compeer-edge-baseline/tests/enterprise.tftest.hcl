mock_provider "cloudflare" {}
variables {
  enabled                     = true
  enforce_enterprise_controls = true
  tunnel_secrets              = { external_nonprod = "MDEyMzQ1Njc4OWFiY2RlZjAxMjM0NTY3ODlhYmNkZWY=" } # Synthetic 32-byte fixture, never a deployment secret.
  approved_public_applications = {
    "pilot.example.com" = { classification = "external-apps", approval_reference = "CHG-test" }
  }
  tunnels = {
    external_nonprod = {
      account_id          = "0123456789abcdef0123456789abcdef"
      name                = "external-nonprod"
      access_team_name    = "compeer-test"
      ingress_rules       = [{ hostname = "pilot.example.com", service = "https://origin.internal:443" }]
      access_applications = { pilot = { name = "Pilot", domain = "pilot.example.com" } }
      access_policies = { pilot = {
        name    = "Approved users", application_key = "pilot", precedence = 1
        include = [{ group = ["00000000-0000-4000-8000-000000000001"] }]
      } }
      dns_records = { pilot = { name = "pilot.example.com", zone_id = "0123456789abcdef0123456789abcdef" } }
    }
  }
}
run "protected_external_app_passes" { command = plan }
run "unapproved_hostname_rejected" {
  command = plan
  variables { approved_public_applications = {} }
  expect_failures = [terraform_data.enterprise_contract]
}
run "internal_classification_rejected" {
  command = plan
  variables {
    approved_public_applications = {
      "pilot.example.com" = { classification = "internal-apps", approval_reference = "CHG-test" }
    }
  }
  expect_failures = [terraform_data.enterprise_contract]
}
run "http_and_missing_access_rejected" {
  command = plan
  variables {
    tunnels = { external_nonprod = {
      account_id    = "0123456789abcdef0123456789abcdef", name = "external-nonprod"
      ingress_rules = [{ hostname = "pilot.example.com", service = "http://origin.internal:80" }]
    } }
  }
  expect_failures = [terraform_data.enterprise_contract]
}
run "approved_public_authentication_exception_passes" {
  command = plan
  variables {
    approved_public_applications = {
      "pilot.example.com" = { classification = "external-apps", approval_reference = "CHG-test", external_authentication_reason = "Approved application-owned customer OIDC authentication" }
    }
    tunnels = { external_nonprod = {
      account_id    = "0123456789abcdef0123456789abcdef", name = "external-nonprod"
      ingress_rules = [{ hostname = "pilot.example.com", service = "https://origin.internal:443" }]
    } }
  }
}
run "managed_waf_execute_supports_existing_zone" {
  command = plan
  variables {
    rulesets = { managed_waf = {
      zone_id = "0123456789abcdef0123456789abcdef"
      name    = "Managed WAF", kind = "zone", phase = "http_request_firewall_managed"
      rules   = [{ action = "execute", expression = "true", action_parameters = { id = "0123456789abcdef0123456789abcdef" } }]
    } }
  }
  assert {
    condition     = cloudflare_ruleset.ruleset["managed_waf"].rules[0].action_parameters[0].id == "0123456789abcdef0123456789abcdef"
    error_message = "Managed WAF ruleset ID must reach execute action parameters."
  }
}

run "custom_and_managed_waf_coexist" {
  command = plan
  variables {
    rulesets = {
      custom = {
        zone_id = "0123456789abcdef0123456789abcdef"
        name    = "Custom WAF", kind = "zone", phase = "http_request_firewall_custom"
        rules   = [{ action = "block", expression = "http.host eq \"pilot.example.com\"" }]
      }
      managed = {
        zone_id = "0123456789abcdef0123456789abcdef"
        name    = "Managed WAF", kind = "zone", phase = "http_request_firewall_managed"
        rules   = [{ action = "execute", expression = "true", action_parameters = { id = "0123456789abcdef0123456789abcdef" } }]
      }
    }
  }
  assert {
    condition = (length(cloudflare_ruleset.ruleset) == 2 &&
      cloudflare_ruleset.ruleset["custom"].rules[0].enabled &&
      cloudflare_ruleset.ruleset["managed"].rules[0].enabled &&
    cloudflare_ruleset.ruleset["managed"].rules[0].action_parameters[0].id == "0123456789abcdef0123456789abcdef")
    error_message = "Custom and managed rules must share a typed contract with safe enabled defaults."
  }
}

run "unsupported_waf_action_parameters_are_rejected" {
  command = plan
  variables {
    rulesets = { managed = {
      zone_id = "0123456789abcdef0123456789abcdef"
      name    = "Managed WAF", kind = "zone", phase = "http_request_firewall_managed"
      rules = [{ action = "execute", expression = "true", action_parameters = {
        id = "0123456789abcdef0123456789abcdef", unsupported = "not-applied"
      } }]
    } }
  }
  expect_failures = [terraform_data.enterprise_contract]
}
