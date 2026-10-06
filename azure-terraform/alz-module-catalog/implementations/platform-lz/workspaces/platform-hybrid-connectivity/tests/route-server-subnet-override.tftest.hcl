mock_provider "azurerm" {}
mock_provider "tfe" {}
mock_provider "time" {}

variables {
  tenant_id                   = "00000000-0000-0000-0000-000000000000"
  subscription_id             = "00000000-0000-0000-0000-000000000000"
  location                    = "centralus"
  environment                 = "prod"
  tfe_organization            = "Compeer-Financial-Services"
  connectivity_workspace_name = "platform-compeer-connectivity"

  platform_tags = {
    application         = "alz-platform-hybrid-connectivity"
    owner               = "Cloud Enablement"
    source_repo         = "ado://Compeer/landing-zone"
    criticality_tier    = "tier-0"
    data_classification = "confidential"
    lifecycle_state     = "active"
    cost_center         = "CC-0000"
    gl_category         = "cloud-infrastructure"
    dr_tier             = "silver"
  }

  hybrid_connectivity = {
    enabled        = true
    resource_group = {}

    route_server_public_ips = {
      primary = {
        name = "platform-cus-prod-rs-pip"
      }
    }

    route_servers = {
      primary = {
        name                             = "platform-cus-prod-rs"
        subnet_key                       = "RouteServerSubnet"
        public_ip_key                    = "primary"
        branch_to_branch_traffic_enabled = false
      }
    }
  }
}

run "explicit_route_server_subnet_id_satisfies_contract" {
  command = plan

  variables {
    use_tfe_outputs = false
    route_server_subnet_ids = {
      primary = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/platform-cus-prod-connectivity-rg/providers/Microsoft.Network/virtualNetworks/platform-cus-prod-hub-vnet/subnets/RouteServerSubnet"
    }
  }

  assert {
    condition     = terraform_data.route_server_subnet_contract.input.resolved_subnet_ids.primary == var.route_server_subnet_ids.primary
    error_message = "explicit route_server_subnet_ids.primary should satisfy Route Server subnet resolution without TFE outputs"
  }
}
