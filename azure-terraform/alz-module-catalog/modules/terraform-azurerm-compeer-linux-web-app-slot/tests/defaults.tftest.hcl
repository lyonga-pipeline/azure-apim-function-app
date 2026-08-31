mock_provider "azurerm" {}

variables {
  name           = "staging"
  app_service_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.Web/sites/app-prod"
}

run "secure_defaults" {
  command = apply

  assert {
    condition     = azurerm_linux_web_app_slot.this.https_only == true
    error_message = "https_only should default true"
  }
  assert {
    condition     = azurerm_linux_web_app_slot.this.public_network_access_enabled == false
    error_message = "public network access should default closed"
  }
}

run "with_stack_and_identity" {
  command = apply

  variables {
    site_config = {
      always_on         = true
      application_stack = { node_version = "20-lts" }
    }
    identity = { type = "SystemAssigned" }
  }

  assert {
    condition     = one(azurerm_linux_web_app_slot.this.site_config).always_on == true
    error_message = "site_config.always_on not wired"
  }
  assert {
    condition     = length(azurerm_linux_web_app_slot.this.identity) == 1
    error_message = "identity block should render"
  }
}
