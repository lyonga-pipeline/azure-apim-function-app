mock_provider "cloudflare" {}

# Exercises terraform_data.tunnel_secret_contract - the precondition that stops
# an enabled tunnel from planning without its sensitive secret already present
# in tunnel_secrets (design doc §8.6: tunnel secrets come from HCP sensitive
# variables, never plaintext tfvars). Had zero test coverage before this file.

run "no_tunnels_is_a_noop" {
  command = plan
  assert {
    condition     = length(terraform_data.tunnel_secret_contract) == 0
    error_message = "no contract resource should exist when there are no enabled tunnels"
  }
}

run "enabled_tunnel_requires_secret" {
  command = plan
  variables {
    enabled = true
    tunnels = {
      external_apps = {
        account_id = "0123456789abcdef0123456789abcdef"
        name       = "compeer-external-apps"
      }
    }
    tunnel_secrets = {}
  }
  expect_failures = [terraform_data.tunnel_secret_contract]
}

run "enabled_tunnel_with_secret_passes" {
  command = plan
  variables {
    enabled = true
    tunnels = {
      external_apps = {
        account_id = "0123456789abcdef0123456789abcdef"
        name       = "compeer-external-apps"
      }
    }
    tunnel_secrets = {
      external_apps = "not-a-real-tunnel-secret"
    }
  }
  assert {
    condition     = length(terraform_data.tunnel_secret_contract) == 1
    error_message = "expected the contract to be created once the secret is present"
  }
}

run "disabled_tunnel_does_not_need_a_secret" {
  command = plan
  variables {
    enabled = true
    tunnels = {
      external_apps = {
        enabled    = false
        account_id = "0123456789abcdef0123456789abcdef"
        name       = "compeer-external-apps"
      }
    }
    tunnel_secrets = {}
  }
  assert {
    condition     = length(terraform_data.tunnel_secret_contract) == 0
    error_message = "a disabled tunnel should not require a secret or create the contract"
  }
}

run "custom_secret_key_is_honored" {
  command = plan
  variables {
    enabled = true
    tunnels = {
      external_apps = {
        account_id        = "0123456789abcdef0123456789abcdef"
        name              = "compeer-external-apps"
        tunnel_secret_key = "shared-edge-secret"
      }
    }
    tunnel_secrets = { shared-edge-secret = "not-a-real-tunnel-secret" }
  }
  assert {
    condition     = length(terraform_data.tunnel_secret_contract) == 1
    error_message = "expected tunnel_secret_key to resolve against tunnel_secrets"
  }
}
