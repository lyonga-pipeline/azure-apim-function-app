mock_provider "cloudflare" {}
variables {
  account_id    = "0123456789abcdef0123456789abcdef"
  name          = "platform-tunnel"
  tunnel_secret = "dGVzdC10dW5uZWwtc2VjcmV0LWJhc2U2NA=="
}
run "create" {
  command = apply
  assert {
    condition     = cloudflare_zero_trust_tunnel_cloudflared.tunnel.name == "platform-tunnel"
    error_message = "tunnel name not wired"
  }
}
run "no_access_resources_by_default" {
  command = plan
  assert {
    condition     = length(cloudflare_zero_trust_access_application.access_application) == 0 && length(cloudflare_zero_trust_access_policy.access_policy) == 0
    error_message = "access resources should be empty by default"
  }
}

run "reject_local_configuration_ownership" {
  command = plan
  variables {
    config_src = "local"
  }
  expect_failures = [var.config_src]
}

run "publish_with_https_and_access" {
  command = apply
  override_resource {
    target = cloudflare_zero_trust_access_application.access_application["pilot"]
    values = { aud = "test-application-audience" }
  }
  variables {
    access_team_name = "compeer-test"
    ingress_rules = [{
      hostname = "pilot.example.com"
      service  = "https://origin.example.internal:443"
      origin_request = {
        no_tls_verify      = false
        origin_server_name = "origin.example.internal"
      }
    }]
    dns_records = {
      pilot = { zone_id = "0123456789abcdef0123456789abcdef", name = "pilot.example.com" }
    }
    access_applications = {
      pilot = { name = "Pilot", domain = "pilot.example.com", session_duration = "8h" }
    }
    access_policies = {
      pilot_users = {
        name            = "Approved pilot users"
        application_key = "pilot"
        precedence      = 1
        include         = [{ group = ["00000000-0000-4000-8000-000000000001"] }]
      }
    }
  }
  assert {
    condition     = contains(keys(module.dns_records.ids), "pilot") && length(cloudflare_zero_trust_access_policy.access_policy) == 1
    error_message = "Publication must preserve the DNS output key and declared Access policy."
  }
  assert {
    condition = (cloudflare_zero_trust_tunnel_cloudflared_config.tunnel_config.config[0].ingress_rule[0].origin_request[0].access[0].required &&
    contains(cloudflare_zero_trust_tunnel_cloudflared_config.tunnel_config.config[0].ingress_rule[0].origin_request[0].access[0].aud_tag, "test-application-audience"))
    error_message = "Connector JWT validation must use the actual Access application audience."
  }
}
