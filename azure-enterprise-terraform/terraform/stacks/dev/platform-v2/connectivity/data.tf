data "terraform_remote_state" "subscriptions" {
  count   = var.use_subscriptions_state ? 1 : 0
  backend = "azurerm"

  config = merge(
    {
      resource_group_name  = var.subscriptions_state_rg
      storage_account_name = var.subscriptions_state_sa
      container_name       = var.subscriptions_state_container
      key                  = var.subscriptions_state_key
      use_azuread_auth     = true
    },
    var.subscriptions_state_subscription_id == null ? {} : {
      subscription_id = var.subscriptions_state_subscription_id
    }
  )
}

locals {
  expected_subscription_id = var.use_subscriptions_state ? try(
    trimspace(data.terraform_remote_state.subscriptions[0].outputs.subscription_catalog[var.subscription_catalog_entry_key].existing_subscription_id),
    null,
  ) : null
}

check "subscription_target_matches_catalog" {
  assert {
    condition     = !var.use_subscriptions_state || local.expected_subscription_id == "" || local.expected_subscription_id == var.subscription_id
    error_message = "The connectivity stack subscription_id does not match the central subscriptions catalog."
  }
}
