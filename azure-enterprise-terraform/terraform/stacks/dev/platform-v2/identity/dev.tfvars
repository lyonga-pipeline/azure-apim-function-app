environment                    = "dev"
subscription_id                = "65ac2b14-e13a-40a0-bb50-93359232816e"
subscription_catalog_entry_key = "identity"
application                    = "identity"
created_by                     = "terraform"
location                       = "eastus2"
resource_group_name            = "rg-dev-identity"
vnet_name                      = "vnet-dev-identity"
key_vault_name                 = "kv-dev-shared-identity"

address_space = [
  "10.30.0.0/16",
]

shared_identity_names = {
  workload_runtime  = "uai-dev-shared-workload-runtime"
  platform_deployer = "uai-dev-platform-deployer"
}

connectivity_state_rg  = "rg-tfstate-dev"
connectivity_state_sa  = "demotest822e"
connectivity_state_key = "stacks/dev/platform-v2/connectivity.tfstate"

management_state_rg  = "rg-tfstate-dev"
management_state_sa  = "demotest822e"
management_state_key = "stacks/dev/platform-v2/management.tfstate"

platform_state_subscription_id      = "65ac2b14-e13a-40a0-bb50-93359232816e"
subscriptions_state_subscription_id = "65ac2b14-e13a-40a0-bb50-93359232816e"
connectivity_state_subscription_id  = "65ac2b14-e13a-40a0-bb50-93359232816e"
management_state_subscription_id    = "65ac2b14-e13a-40a0-bb50-93359232816e"

business_owner      = "identity-engineering"
source_repo         = "azure-apim-function-app"
terraform_workspace = "platform-v2-identity-dev"
recovery_tier       = "terraform"
cost_center         = "shared-identity"
creation_date_utc   = "2026-03-10T00:00:00Z"

additional_tags = {
  owner = "charles"
}
