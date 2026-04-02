environment                    = "dev"
subscription_id                = "65ac2b14-e13a-40a0-bb50-93359232816e"
subscription_catalog_entry_key = "connectivity"
application                    = "connectivity"
created_by                     = "terraform"
location                       = "eastus2"
resource_group_name            = "rg-dev-connectivity"
hub_vnet_name                  = "vnet-dev-hub"

hub_address_space = [
  "10.0.0.0/16",
]

enable_firewall = true
firewall_network_rule_collections = [
  {
    name     = "spoke-to-internet"
    priority = 100
    action   = "Allow"
    rules = [
      {
        name                  = "allow-web"
        source_addresses      = ["10.0.0.0/16", "10.20.0.0/16"]
        destination_ports     = ["80", "443"]
        destination_addresses = ["*"]
        protocols             = ["TCP"]
      }
    ]
  }
]

enable_nat_gateway = true

enable_bastion      = true
business_owner      = "network"
source_repo         = "azure-apim-function-app"
terraform_workspace = "platform-v2-connectivity-dev"
recovery_tier       = "terraform"
cost_center         = "shared-network"
creation_date_utc   = "2026-03-09T00:00:00Z"

subscriptions_state_subscription_id = "65ac2b14-e13a-40a0-bb50-93359232816e"

additional_tags = {
  owner = "charles"
}
