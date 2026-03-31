# Execution subscription used by this stack to access the remote-state storage
# account and write the subscriptions catalog state. This does not need to be
# one of the catalog entries below.
subscription_id = "65ac2b14-e13a-40a0-bb50-93359232816e"

# Recommended enterprise model:
# - dedicated platform subscriptions for connectivity, management, identity,
#   and security shared services
# - separate application landing-zone subscriptions for workload environments
# - optional sandbox and decommissioned subscriptions for their own lifecycle
#
# Keep existing_subscription_id blank until the real subscription has been
# created or assigned. Blank values are filtered out from the management-group
# association output, so the catalog can be applied safely before subscription
# vending is complete.
target_subscriptions = {
  connectivity = {
    management_group_key      = "connectivity"
    existing_subscription_id  = ""
    subscription_display_name = "FinServ Connectivity"
  }

  management = {
    management_group_key      = "management"
    existing_subscription_id  = ""
    subscription_display_name = "FinServ Management"
  }

  identity = {
    management_group_key      = "identity"
    existing_subscription_id  = ""
    subscription_display_name = "FinServ Identity"
  }

  security = {
    management_group_key      = "security"
    existing_subscription_id  = ""
    subscription_display_name = "FinServ Security"
  }

  nonprod_finserv_api = {
    management_group_key      = "nonprod"
    existing_subscription_id  = ""
    subscription_display_name = "FinServ API Nonprod"
  }

  prod_finserv_api = {
    management_group_key      = "prod"
    existing_subscription_id  = ""
    subscription_display_name = "FinServ API Prod"
  }

  sandbox_shared = {
    management_group_key      = "sandbox"
    existing_subscription_id  = ""
    subscription_display_name = "FinServ Sandbox"
  }

  decommissioned_archive = {
    management_group_key      = "decommissioned"
    existing_subscription_id  = ""
    subscription_display_name = "FinServ Decommissioned"
  }
}
