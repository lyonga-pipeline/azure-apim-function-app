module "tags" {
  source              = "../../../../modules/platform-tags"
  environment         = var.environment
  application         = var.application
  created_by          = var.created_by
  business_owner      = var.business_owner
  source_repo         = var.source_repo
  terraform_workspace = var.terraform_workspace
  recovery_tier       = var.recovery_tier
  cost_center         = var.cost_center
  compliance_boundary = var.compliance_boundary
  creation_date_utc   = var.creation_date_utc
  last_modified_utc   = var.last_modified_utc
  additional_tags     = var.additional_tags
}

module "resource_group" {
  source   = "../../../../modules/resource_group"
  name     = var.resource_group_name
  location = var.location
  tags     = module.tags.tags
}

module "hub_network" {
  source                                         = "../../../../modules/vnet-hub"
  name                                           = var.hub_vnet_name
  resource_group_name                            = module.resource_group.name
  location                                       = var.location
  address_space                                  = var.hub_address_space
  dns_servers                                    = var.dns_servers
  enable_firewall                                = var.enable_firewall
  firewall_sku_tier                              = var.firewall_sku_tier
  firewall_network_rule_collections              = var.firewall_network_rule_collections
  firewall_policy_name                           = var.firewall_policy_name
  firewall_policy_rule_collection_group_name     = var.firewall_policy_rule_collection_group_name
  firewall_policy_rule_collection_group_priority = var.firewall_policy_rule_collection_group_priority
  firewall_threat_intelligence_mode              = var.firewall_threat_intelligence_mode
  enable_nat_gateway                             = var.enable_nat_gateway
  nat_gateway_name                               = var.nat_gateway_name
  nat_gateway_subnet_keys                        = var.nat_gateway_subnet_keys
  nat_gateway_create_public_ip                   = var.nat_gateway_create_public_ip
  nat_gateway_idle_timeout_in_minutes            = var.nat_gateway_idle_timeout_in_minutes
  nat_gateway_zones                              = var.nat_gateway_zones
  enable_bastion                                 = var.enable_bastion
  bastion_name                                   = var.bastion_name
  bastion_sku                                    = var.bastion_sku
  bastion_copy_paste_enabled                     = var.bastion_copy_paste_enabled
  bastion_file_copy_enabled                      = var.bastion_file_copy_enabled
  bastion_ip_connect_enabled                     = var.bastion_ip_connect_enabled
  bastion_shareable_link_enabled                 = var.bastion_shareable_link_enabled
  bastion_tunneling_enabled                      = var.bastion_tunneling_enabled
  bastion_scale_units                            = var.bastion_scale_units
  tags                                           = module.tags.tags
}

module "private_dns" {
  source              = "../../../../modules/private-dns"
  resource_group_name = module.resource_group.name
  location            = var.location
  zones               = var.private_dns_zones
  vnet_ids_to_link = {
    hub = module.hub_network.vnet_id
  }
  tags = module.tags.tags
}
