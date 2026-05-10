locals {
  name_prefix = "${var.application_name}-${var.environment}"
  common_tags = merge(var.tags, {
    application = var.application_name
    environment = var.environment
  })
}

module "resource_group" {
  source   = "../../azure-terraform/modules/resource-group"
  name     = try(var.resource_group.name, "${local.name_prefix}-rg")
  location = var.location
  tags     = merge(local.common_tags, try(var.resource_group.tags, {}))
}

module "log_analytics" {
  source              = "../../azure-terraform/modules/log-analytics"
  name                = try(var.log_analytics.name, "${local.name_prefix}-law")
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  sku                 = try(var.log_analytics.sku, null)
  retention_in_days   = try(var.log_analytics.retention_in_days, null)
  tags                = merge(local.common_tags, try(var.log_analytics.tags, {}))
}

module "action_group" {
  source              = "../../azure-terraform/modules/action-group"
  name                = try(var.action_group.name, "${local.name_prefix}-ag")
  resource_group_name = module.resource_group.name
  short_name          = var.action_group.short_name
  enabled             = try(var.action_group.enabled, null)
  receivers           = try(var.action_group.receivers, {})
  tags                = merge(local.common_tags, try(var.action_group.tags, {}))
}

module "virtual_network" {
  source              = "../../azure-terraform/modules/virtual-network"
  name                = try(var.virtual_network.name, "${local.name_prefix}-vnet")
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  address_space       = var.virtual_network.address_space
  dns_servers         = try(var.virtual_network.dns_servers, null)
  subnets             = try(var.virtual_network.subnets, {})
  tags                = merge(local.common_tags, try(var.virtual_network.tags, {}))
}

module "route_table" {
  source                        = "../../azure-terraform/modules/route-table"
  name                          = try(var.route_table.name, "${local.name_prefix}-rt")
  resource_group_name           = module.resource_group.name
  location                      = module.resource_group.location
  bgp_route_propagation_enabled = try(var.route_table.bgp_route_propagation_enabled, null)
  routes                        = try(var.route_table.routes, {})
  tags                          = merge(local.common_tags, try(var.route_table.tags, {}))
}

module "servers_subnet_route_table_association" {
  source         = "../../azure-terraform/modules/subnet-route-table-association"
  subnet_id      = module.virtual_network.subnet_ids[var.network_interface.subnet_name]
  route_table_id = module.route_table.id
}

module "network_security_group" {
  source              = "../../azure-terraform/modules/network-security-group"
  name                = try(var.network_security_group.name, "${local.name_prefix}-nsg")
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  rules               = try(var.network_security_group.rules, {})
  tags                = merge(local.common_tags, try(var.network_security_group.tags, {}))
}

module "servers_subnet_nsg_association" {
  source                    = "../../azure-terraform/modules/nsg-subnet-association"
  subnet_id                 = module.virtual_network.subnet_ids[var.network_interface.subnet_name]
  network_security_group_id = module.network_security_group.id
}

module "private_dns_zones" {
  source = "../../azure-terraform/modules/private-dns-zone"
  zones  = var.private_dns_zones
  tags   = local.common_tags
}

module "private_dns_links" {
  source = "../../azure-terraform/modules/private-dns-vnet-link"
  links = {
    for key, value in var.private_dns_links :
    key => merge(value, { virtual_network_id = module.virtual_network.id })
  }
  tags = local.common_tags
}

module "nat_public_ip" {
  source              = "../../azure-terraform/modules/public-ip"
  name                = try(var.nat_public_ip.name, "${local.name_prefix}-nat-pip")
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  allocation_method   = try(var.nat_public_ip.allocation_method, null)
  sku                 = try(var.nat_public_ip.sku, null)
  sku_tier            = try(var.nat_public_ip.sku_tier, null)
  zones               = try(var.nat_public_ip.zones, [])
  tags                = merge(local.common_tags, try(var.nat_public_ip.tags, {}))
}

module "nat_gateway" {
  source                  = "../../azure-terraform/modules/nat-gateway"
  name                    = try(var.nat_gateway.name, "${local.name_prefix}-nat")
  resource_group_name     = module.resource_group.name
  location                = module.resource_group.location
  sku_name                = try(var.nat_gateway.sku_name, null)
  idle_timeout_in_minutes = try(var.nat_gateway.idle_timeout_in_minutes, null)
  zones                   = try(var.nat_gateway.zones, [])
  tags                    = merge(local.common_tags, try(var.nat_gateway.tags, {}))
}

module "nat_gateway_public_ip_association" {
  source = "../../azure-terraform/modules/nat-gateway-public-ip-association"
  associations = {
    primary = {
      nat_gateway_id       = module.nat_gateway.id
      public_ip_address_id = module.nat_public_ip.id
    }
  }
}

module "nat_gateway_subnet_association" {
  source                = "../../azure-terraform/modules/nat-gateway-associations"
  nat_gateway_id        = module.nat_gateway.id
  public_ip_address_ids = []
  subnet_ids            = [module.virtual_network.subnet_ids[var.network_interface.subnet_name]]
}

module "load_balancer_public_ip" {
  source              = "../../azure-terraform/modules/public-ip"
  name                = try(var.load_balancer_public_ip.name, "${local.name_prefix}-lb-pip")
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  allocation_method   = try(var.load_balancer_public_ip.allocation_method, null)
  sku                 = try(var.load_balancer_public_ip.sku, null)
  sku_tier            = try(var.load_balancer_public_ip.sku_tier, null)
  zones               = try(var.load_balancer_public_ip.zones, [])
  tags                = merge(local.common_tags, try(var.load_balancer_public_ip.tags, {}))
}

module "storage_account" {
  source                            = "../../azure-terraform/modules/storage-account"
  name                              = var.storage_account.name
  resource_group_name               = module.resource_group.name
  location                          = module.resource_group.location
  account_tier                      = try(var.storage_account.account_tier, null)
  account_replication_type          = try(var.storage_account.account_replication_type, null)
  account_kind                      = try(var.storage_account.account_kind, null)
  access_tier                       = try(var.storage_account.access_tier, null)
  min_tls_version                   = try(var.storage_account.min_tls_version, null)
  public_network_access_enabled     = try(var.storage_account.public_network_access_enabled, null)
  allow_nested_items_to_be_public   = try(var.storage_account.allow_nested_items_to_be_public, null)
  shared_access_key_enabled         = try(var.storage_account.shared_access_key_enabled, null)
  infrastructure_encryption_enabled = try(var.storage_account.infrastructure_encryption_enabled, null)
  tags                              = merge(local.common_tags, try(var.storage_account.tags, {}))
}

module "key_vault" {
  source                        = "../../azure-terraform/modules/key-vault"
  name                          = try(var.key_vault.name, "${local.name_prefix}-kv")
  resource_group_name           = module.resource_group.name
  location                      = module.resource_group.location
  tenant_id                     = var.tenant_id
  enable_rbac_authorization     = false
  public_network_access_enabled = try(var.key_vault.public_network_access_enabled, null)
  purge_protection_enabled      = try(var.key_vault.purge_protection_enabled, null)
  network_acls                  = try(var.key_vault.network_acls, {})
  tags                          = merge(local.common_tags, try(var.key_vault.tags, {}))
}

module "key_vault_secrets" {
  source       = "../../azure-terraform/modules/key-vault-secret"
  key_vault_id = module.key_vault.id
  secrets      = var.key_vault_secrets
  tags         = local.common_tags
}

module "key_vault_access_policies" {
  source       = "../../azure-terraform/modules/key-vault-access-policy"
  key_vault_id = module.key_vault.id
  policies     = var.key_vault_access_policies
}

module "network_interface" {
  source              = "../../azure-terraform/modules/network-interface"
  name                = try(var.network_interface.name, "${local.name_prefix}-nic")
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  ip_configurations = {
    for key, value in var.network_interface.ip_configurations :
    key => merge(value, {
      subnet_id = module.virtual_network.subnet_ids[var.network_interface.subnet_name]
    })
  }
  dns_servers                    = try(var.network_interface.dns_servers, null)
  accelerated_networking_enabled = try(var.network_interface.accelerated_networking_enabled, null)
  ip_forwarding_enabled          = try(var.network_interface.ip_forwarding_enabled, null)
  tags                           = merge(local.common_tags, try(var.network_interface.tags, {}))
}

module "nsg_network_interface_association" {
  source                    = "../../azure-terraform/modules/nsg-network-interface-association"
  network_interface_id      = module.network_interface.id
  network_security_group_id = module.network_security_group.id
}

resource "azurerm_application_security_group" "this" {
  name                = var.application_security_group.name
  location            = module.resource_group.location
  resource_group_name = module.resource_group.name
  tags                = merge(local.common_tags, try(var.application_security_group.tags, {}))
}

module "network_interface_application_security_group_association" {
  source = "../../azure-terraform/modules/network-interface-application-security-group-association"
  associations = {
    primary = {
      network_interface_id          = module.network_interface.id
      application_security_group_id = azurerm_application_security_group.this.id
    }
  }
}

module "availability_set" {
  source              = "../../azure-terraform/modules/availability-set"
  name                = try(var.availability_set.name, "${local.name_prefix}-as")
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  tags                = merge(local.common_tags, try(var.availability_set.tags, {}))
}

module "windows_vm" {
  source                     = "../../azure-terraform/modules/windows-vm"
  name                       = try(var.windows_vm.name, "${local.name_prefix}-vm")
  resource_group_name        = module.resource_group.name
  location                   = module.resource_group.location
  vm_size                    = try(var.windows_vm.vm_size, null)
  network_interface_ids      = [module.network_interface.id]
  admin_username             = var.windows_vm.admin_username
  admin_password             = var.windows_vm.admin_password
  computer_name              = try(var.windows_vm.computer_name, null)
  availability_set_id        = module.availability_set.id
  zone                       = try(var.windows_vm.zone, null)
  source_image_id            = try(var.windows_vm.source_image_id, null)
  source_image_reference     = try(var.windows_vm.source_image_reference, null)
  plan                       = try(var.windows_vm.plan, null)
  license_type               = try(var.windows_vm.license_type, null)
  timezone                   = try(var.windows_vm.timezone, null)
  provision_vm_agent         = try(var.windows_vm.provision_vm_agent, null)
  allow_extension_operations = try(var.windows_vm.allow_extension_operations, null)
  enable_automatic_updates   = try(var.windows_vm.enable_automatic_updates, null)
  patch_mode                 = try(var.windows_vm.patch_mode, null)
  patch_assessment_mode      = try(var.windows_vm.patch_assessment_mode, null)
  hotpatching_enabled        = try(var.windows_vm.hotpatching_enabled, null)
  secure_boot_enabled        = try(var.windows_vm.secure_boot_enabled, null)
  vtpm_enabled               = try(var.windows_vm.vtpm_enabled, null)
  encryption_at_host_enabled = try(var.windows_vm.encryption_at_host_enabled, null)
  identity                   = try(var.windows_vm.identity, null)
  boot_diagnostics = {
    storage_account_uri = module.storage_account.primary_blob_endpoint
  }
  additional_capabilities = try(var.windows_vm.additional_capabilities, null)
  os_disk                 = try(var.windows_vm.os_disk, null)
  tags                    = merge(local.common_tags, try(var.windows_vm.tags, {}))
}

module "windows_vm_data_disks" {
  source              = "../../azure-terraform/modules/windows-vm-data-disks"
  name_prefix         = local.name_prefix
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  virtual_machine_id  = module.windows_vm.id
  zone                = try(var.windows_vm_data_disks.zone, null)
  disks               = var.windows_vm_data_disks.disks
  tags                = local.common_tags
}

module "windows_vm_domain_join" {
  source             = "../../azure-terraform/modules/windows-vm-domain-join"
  name               = try(var.windows_vm_domain_join.name, "domain-join")
  virtual_machine_id = module.windows_vm.id
  domain_name        = var.windows_vm_domain_join.domain_name
  ou_path            = try(var.windows_vm_domain_join.ou_path, null)
  domain_username    = var.windows_vm_domain_join.domain_username
  domain_password    = var.windows_vm_domain_join.domain_password
  restart            = try(var.windows_vm_domain_join.restart, null)
  join_options       = try(var.windows_vm_domain_join.join_options, null)
}

module "windows_vm_extensions" {
  source             = "../../azure-terraform/modules/windows-vm-extension"
  virtual_machine_id = module.windows_vm.id
  extensions         = var.windows_vm_extensions
}

module "load_balancer" {
  source              = "../../azure-terraform/modules/load-balancer"
  name                = try(var.load_balancer.name, "${local.name_prefix}-lb")
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  sku                 = try(var.load_balancer.sku, null)
  edge_zone           = try(var.load_balancer.edge_zone, null)
  frontend_ip_configurations = {
    public = {
      public_ip_address_id = module.load_balancer_public_ip.id
    }
  }
  backend_address_pools = try(var.load_balancer.backend_address_pools, {})
  probes                = try(var.load_balancer.probes, {})
  rules                 = try(var.load_balancer.rules, {})
  tags                  = merge(local.common_tags, try(var.load_balancer.tags, {}))
}

resource "azurerm_network_interface_backend_address_pool_association" "this" {
  network_interface_id    = module.network_interface.id
  ip_configuration_name   = var.network_interface.primary_ip_configuration_name
  backend_address_pool_id = module.load_balancer.backend_pool_ids[var.load_balancer.primary_backend_pool_name]
}

module "sql_server" {
  source                                       = "../../azure-terraform/modules/sql-server"
  name                                         = try(var.sql_server.name, "${local.name_prefix}-sql")
  resource_group_name                          = module.resource_group.name
  location                                     = module.resource_group.location
  server_version                               = try(var.sql_server.server_version, null)
  minimum_tls_version                          = try(var.sql_server.minimum_tls_version, null)
  connection_policy                            = try(var.sql_server.connection_policy, null)
  public_network_access_enabled                = try(var.sql_server.public_network_access_enabled, null)
  outbound_network_restriction_enabled         = try(var.sql_server.outbound_network_restriction_enabled, null)
  express_vulnerability_assessment_enabled     = try(var.sql_server.express_vulnerability_assessment_enabled, null)
  azuread_authentication_only                  = try(var.sql_server.azuread_authentication_only, null)
  azuread_administrator                        = try(var.sql_server.azuread_administrator, null)
  administrator_login                          = try(var.sql_server.administrator_login, null)
  administrator_login_password                 = try(var.sql_server.administrator_login_password, null)
  identity                                     = try(var.sql_server.identity, null)
  primary_user_assigned_identity_id            = try(var.sql_server.primary_user_assigned_identity_id, null)
  transparent_data_encryption_key_vault_key_id = try(var.sql_server.transparent_data_encryption_key_vault_key_id, null)
  tags                                         = merge(local.common_tags, try(var.sql_server.tags, {}))
}

module "sql_databases" {
  source    = "../../azure-terraform/modules/sql-database"
  server_id = module.sql_server.id
  databases = var.sql_databases
  tags      = local.common_tags
}

module "sql_auditing_policy" {
  source                   = "../../azure-terraform/modules/sql-server-extended-auditing-policy"
  server_id                = module.sql_server.id
  enabled                  = try(var.sql_auditing_policy.enabled, null)
  log_monitoring_enabled   = try(var.sql_auditing_policy.log_monitoring_enabled, null)
  predicate_expression     = try(var.sql_auditing_policy.predicate_expression, null)
  retention_in_days        = try(var.sql_auditing_policy.retention_in_days, null)
  audit_actions_and_groups = try(var.sql_auditing_policy.audit_actions_and_groups, null)
  storage_endpoint         = try(var.sql_auditing_policy.storage_endpoint, null)
}

module "sql_security_alert_policy" {
  source               = "../../azure-terraform/modules/sql-server-security-alert-policy"
  resource_group_name  = module.sql_server.resource_group_name
  server_name          = module.sql_server.name
  state                = var.sql_security_alert_policy.state
  disabled_alerts      = try(var.sql_security_alert_policy.disabled_alerts, [])
  email_account_admins = try(var.sql_security_alert_policy.email_account_admins, null)
  email_addresses      = try(var.sql_security_alert_policy.email_addresses, [])
  retention_days       = try(var.sql_security_alert_policy.retention_days, null)
  storage_endpoint     = try(var.sql_security_alert_policy.storage_endpoint, null)
}

module "sql_private_endpoint" {
  source                     = "../../azure-terraform/modules/private-endpoint"
  name                       = try(var.sql_private_endpoint.name, "${local.name_prefix}-sql-pe")
  resource_group_name        = module.resource_group.name
  location                   = module.resource_group.location
  subnet_id                  = module.virtual_network.subnet_ids[var.sql_private_endpoint.subnet_name]
  private_service_connection = merge(var.sql_private_endpoint.private_service_connection, { private_connection_resource_id = module.sql_server.id })
  private_dns_zone_group     = try(var.sql_private_endpoint.private_dns_zone_group, null)
  ip_configurations          = try(var.sql_private_endpoint.ip_configurations, {})
  tags                       = merge(local.common_tags, try(var.sql_private_endpoint.tags, {}))
}

module "private_dns_records" {
  source = "../../azure-terraform/modules/private-dns-a-record"
  records = {
    for key, value in var.private_dns_records :
    key => merge(value, {
      records = [module.load_balancer_public_ip.ip_address]
    })
  }
  tags = local.common_tags
}

module "vm_key_vault_access_policy" {
  source       = "../../azure-terraform/modules/key-vault-access-policy"
  key_vault_id = module.key_vault.id
  policies = {
    vm = {
      tenant_id          = var.tenant_id
      object_id          = module.windows_vm.identity[0].principal_id
      secret_permissions = ["Get", "List"]
    }
  }
}

module "key_vault_diagnostics" {
  source                     = "../../azure-terraform/modules/diagnostic-settings"
  name                       = try(var.key_vault_diagnostics.name, "${local.name_prefix}-kv-diag")
  target_resource_id         = module.key_vault.id
  log_analytics_workspace_id = module.log_analytics.id
  logs                       = try(var.key_vault_diagnostics.logs, {})
  metrics                    = try(var.key_vault_diagnostics.metrics, {})
}

module "sql_diagnostics" {
  source                     = "../../azure-terraform/modules/diagnostic-settings"
  name                       = try(var.sql_diagnostics.name, "${local.name_prefix}-sql-diag")
  target_resource_id         = module.sql_server.id
  log_analytics_workspace_id = module.log_analytics.id
  logs                       = try(var.sql_diagnostics.logs, {})
  metrics                    = try(var.sql_diagnostics.metrics, {})
}
