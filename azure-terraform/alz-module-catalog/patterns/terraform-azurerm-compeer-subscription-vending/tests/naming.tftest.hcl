mock_provider "azurerm" {}

variables {
  subscription_id = "00000000-0000-0000-0000-000000000000"
  vending_enabled = true
  management_groups = {
    security = {}
  }
  default_billing_scope_id = "/providers/Microsoft.Billing/billingAccounts/00000000/billingProfiles/00000000/invoiceSections/00000000"
}

run "subscription_name_defaults_to_naming_module_when_purpose_is_set" {
  command = plan

  variables {
    subscriptions = {
      platform_security = {
        purpose              = "security"
        management_group_key = "security"
      }
    }
  }

  assert {
    condition     = local.subscription_inputs["platform_security"].subscription_name == "sub-security-shared-cus"
    error_message = "subscription_name should default to the naming module's subscription_scoped pattern (sub-<purpose>-<env>-<region>) when purpose is set"
  }
}

run "explicit_subscription_name_overrides_naming_default" {
  command = plan

  variables {
    subscriptions = {
      platform_security = {
        subscription_name    = "platform-security-sub"
        purpose              = "security"
        management_group_key = "security"
      }
    }
  }

  assert {
    condition     = local.subscription_inputs["platform_security"].subscription_name == "platform-security-sub"
    error_message = "an explicit subscription_name must win over the naming module default"
  }
}

run "falls_back_to_map_key_without_purpose_or_explicit_name" {
  command = plan

  variables {
    subscriptions = {
      sandbox_ops = {
        management_group_key = "security"
      }
    }
  }

  assert {
    condition     = local.subscription_inputs["sandbox_ops"].subscription_name == "sandbox_ops"
    error_message = "without purpose or an explicit name, the map key remains the last-resort name (unchanged prior behaviour)"
  }
}
