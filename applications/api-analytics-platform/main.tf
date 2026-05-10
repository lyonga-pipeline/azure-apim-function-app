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

module "gateway_public_ip" {
  source              = "../../azure-terraform/modules/public-ip"
  name                = try(var.gateway_public_ip.name, "${local.name_prefix}-agw-pip")
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  allocation_method   = try(var.gateway_public_ip.allocation_method, null)
  sku                 = try(var.gateway_public_ip.sku, null)
  sku_tier            = try(var.gateway_public_ip.sku_tier, null)
  zones               = try(var.gateway_public_ip.zones, [])
  tags                = merge(local.common_tags, try(var.gateway_public_ip.tags, {}))
}

module "key_vault" {
  source                        = "../../azure-terraform/modules/key-vault"
  name                          = try(var.key_vault.name, "${local.name_prefix}-kv")
  resource_group_name           = module.resource_group.name
  location                      = module.resource_group.location
  tenant_id                     = var.tenant_id
  enable_rbac_authorization     = true
  public_network_access_enabled = try(var.key_vault.public_network_access_enabled, null)
  purge_protection_enabled      = try(var.key_vault.purge_protection_enabled, null)
  network_acls                  = try(var.key_vault.network_acls, {})
  contacts                      = try(var.key_vault.contacts, {})
  tags                          = merge(local.common_tags, try(var.key_vault.tags, {}))
}

module "key_vault_secrets" {
  source       = "../../azure-terraform/modules/key-vault-secret"
  key_vault_id = module.key_vault.id
  secrets      = var.key_vault_secrets
  tags         = local.common_tags
}

module "key_vault_certificates" {
  source       = "../../azure-terraform/modules/key-vault-certificate"
  key_vault_id = module.key_vault.id
  certificates = var.key_vault_certificates
  tags         = local.common_tags
}

module "managed_hsm" {
  source                        = "../../azure-terraform/modules/key-vault-managed-hsm"
  name                          = try(var.key_vault_managed_hsm.name, "${local.name_prefix}-mhsm")
  resource_group_name           = module.resource_group.name
  location                      = module.resource_group.location
  tenant_id                     = var.tenant_id
  sku_name                      = try(var.key_vault_managed_hsm.sku_name, null)
  purge_protection_enabled      = try(var.key_vault_managed_hsm.purge_protection_enabled, null)
  soft_delete_retention_days    = try(var.key_vault_managed_hsm.soft_delete_retention_days, null)
  public_network_access_enabled = try(var.key_vault_managed_hsm.public_network_access_enabled, null)
  admin_object_ids              = var.key_vault_managed_hsm.admin_object_ids
  network_acls                  = try(var.key_vault_managed_hsm.network_acls, {})
  tags                          = merge(local.common_tags, try(var.key_vault_managed_hsm.tags, {}))
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
  is_hns_enabled                    = true
  tags                              = merge(local.common_tags, try(var.storage_account.tags, {}))
}

module "synapse_filesystem" {
  source             = "../../azure-terraform/modules/synapse-filesystem"
  name               = var.synapse_filesystem.name
  storage_account_id = module.storage_account.id
  owner              = try(var.synapse_filesystem.owner, null)
  group              = try(var.synapse_filesystem.group, null)
  properties         = try(var.synapse_filesystem.properties, {})
}

module "synapse_workspace" {
  source                               = "../../azure-terraform/modules/synapse-workspace"
  name                                 = try(var.synapse_workspace.name, "${local.name_prefix}-syn")
  resource_group_name                  = module.resource_group.name
  location                             = module.resource_group.location
  storage_data_lake_gen2_filesystem_id = module.synapse_filesystem.id
  sql_administrator_login              = var.synapse_workspace.sql_administrator_login
  sql_administrator_login_password     = var.synapse_workspace.sql_administrator_login_password
  managed_virtual_network_enabled      = try(var.synapse_workspace.managed_virtual_network_enabled, null)
  data_exfiltration_protection_enabled = try(var.synapse_workspace.data_exfiltration_protection_enabled, null)
  identity                             = try(var.synapse_workspace.identity, null)
  tags                                 = merge(local.common_tags, try(var.synapse_workspace.tags, {}))
}

module "synapse_workspace_aad_admin" {
  source               = "../../azure-terraform/modules/synapse-workspace-aad-admin"
  synapse_workspace_id = module.synapse_workspace.id
  login                = var.synapse_workspace_aad_admin.login
  object_id            = var.synapse_workspace_aad_admin.object_id
  tenant_id            = var.tenant_id
}

module "application_gateway" {
  source                            = "../../azure-terraform/modules/application-gateway"
  name                              = try(var.application_gateway.name, "${local.name_prefix}-agw")
  resource_group_name               = module.resource_group.name
  location                          = module.resource_group.location
  enable_http2                      = try(var.application_gateway.enable_http2, null)
  firewall_policy_id                = try(var.application_gateway.firewall_policy_id, null)
  force_firewall_policy_association = try(var.application_gateway.force_firewall_policy_association, null)
  identity                          = try(var.application_gateway.identity, null)
  sku                               = var.application_gateway.sku
  autoscale_configuration           = try(var.application_gateway.autoscale_configuration, null)
  gateway_ip_configurations = {
    gateway = {
      subnet_id = module.virtual_network.subnet_ids[var.application_gateway.gateway_subnet_name]
    }
  }
  frontend_ports = var.application_gateway.frontend_ports
  frontend_ip_configurations = {
    public = {
      public_ip_address_id = module.gateway_public_ip.id
    }
  }
  ssl_policy                  = try(var.application_gateway.ssl_policy, null)
  ssl_certificates            = try(var.application_gateway.ssl_certificates, {})
  trusted_root_certificates   = try(var.application_gateway.trusted_root_certificates, {})
  trusted_client_certificates = try(var.application_gateway.trusted_client_certificates, {})
  backend_address_pools       = try(var.application_gateway.backend_address_pools, {})
  probes                      = try(var.application_gateway.probes, {})
  backend_http_settings       = try(var.application_gateway.backend_http_settings, {})
  http_listeners              = try(var.application_gateway.http_listeners, {})
  redirect_configurations     = try(var.application_gateway.redirect_configurations, {})
  rewrite_rule_sets           = try(var.application_gateway.rewrite_rule_sets, {})
  url_path_maps               = try(var.application_gateway.url_path_maps, {})
  waf_configuration           = try(var.application_gateway.waf_configuration, null)
  request_routing_rules       = try(var.application_gateway.request_routing_rules, {})
  tags                        = merge(local.common_tags, try(var.application_gateway.tags, {}))
}

module "apim_service" {
  source                        = "../../azure-terraform/modules/apim-service"
  name                          = try(var.apim_service.name, "${local.name_prefix}-apim")
  resource_group_name           = module.resource_group.name
  location                      = module.resource_group.location
  publisher_name                = var.apim_service.publisher_name
  publisher_email               = var.apim_service.publisher_email
  sku_name                      = var.apim_service.sku_name
  public_network_access_enabled = try(var.apim_service.public_network_access_enabled, null)
  virtual_network_type          = try(var.apim_service.virtual_network_type, null)
  virtual_network_configuration = try(var.apim_service.virtual_network_type, "None") == "None" ? null : {
    subnet_id = module.virtual_network.subnet_ids[var.apim_service.subnet_name]
  }
  identity  = try(var.apim_service.identity, null)
  security  = try(var.apim_service.security, null)
  protocols = try(var.apim_service.protocols, null)
  sign_in   = try(var.apim_service.sign_in, null)
  sign_up   = try(var.apim_service.sign_up, null)
  tags      = merge(local.common_tags, try(var.apim_service.tags, {}))
}

module "apim_custom_domain" {
  source            = "../../azure-terraform/modules/apim-custom-domain"
  api_management_id = module.apim_service.id
  gateway = {
    for key, value in try(var.apim_custom_domain.gateway, {}) :
    key => merge(value, {
      key_vault_certificate_id = module.key_vault_certificates.ids[value.certificate_name]
    })
  }
  developer_portal = try(var.apim_custom_domain.developer_portal, {})
  management       = try(var.apim_custom_domain.management, {})
  portal           = try(var.apim_custom_domain.portal, {})
  scm              = try(var.apim_custom_domain.scm, {})
}

module "apim_named_values" {
  source              = "../../azure-terraform/modules/apim-named-value"
  resource_group_name = module.resource_group.name
  api_management_name = module.apim_service.name
  named_values = {
    for key, value in var.apim_named_values :
    key => (
      try(value.secret_key_name, null) == null ?
      value :
      merge(value, {
        value_from_key_vault = {
          secret_id = module.key_vault_secrets.ids[value.secret_key_name]
        }
      })
    )
  }
}

module "apim_backend" {
  source              = "../../azure-terraform/modules/apim-backend"
  name                = try(var.apim_backend.name, "${local.name_prefix}-backend")
  resource_group_name = module.resource_group.name
  api_management_name = module.apim_service.name
  protocol            = var.apim_backend.protocol
  url                 = var.apim_backend.url
  description         = try(var.apim_backend.description, null)
  resource_id         = try(var.apim_backend.resource_id, null)
  title               = try(var.apim_backend.title, null)
  credentials         = try(var.apim_backend.credentials, null)
  proxy               = try(var.apim_backend.proxy, null)
  tls                 = try(var.apim_backend.tls, null)
}

module "apim_api" {
  source                           = "../../azure-terraform/modules/apim-api"
  name                             = var.apim_api.name
  resource_group_name              = module.resource_group.name
  api_management_name              = module.apim_service.name
  display_name                     = var.apim_api.display_name
  path                             = var.apim_api.path
  revision                         = try(var.apim_api.revision, null)
  protocols                        = try(var.apim_api.protocols, null)
  service_url                      = try(var.apim_api.service_url, null)
  subscription_required            = try(var.apim_api.subscription_required, null)
  api_version                      = try(var.apim_api.api_version, null)
  version_set_id                   = try(var.apim_api.version_set_id, null)
  api_type                         = try(var.apim_api.api_type, null)
  description                      = try(var.apim_api.description, null)
  import                           = try(var.apim_api.import, null)
  subscription_key_parameter_names = try(var.apim_api.subscription_key_parameter_names, null)
}

module "apim_policy" {
  source            = "../../azure-terraform/modules/apim-policy"
  api_management_id = module.apim_service.id
  xml_content       = try(var.apim_policy.xml_content, null)
  xml_link          = try(var.apim_policy.xml_link, null)
}

module "apim_api_policy" {
  source              = "../../azure-terraform/modules/apim-api-policy"
  resource_group_name = module.resource_group.name
  api_management_name = module.apim_service.name
  api_name            = module.apim_api.name
  xml_content         = try(var.apim_api_policy.xml_content, null)
  xml_link            = try(var.apim_api_policy.xml_link, null)
}

module "apim_product" {
  source                = "../../azure-terraform/modules/apim-product"
  product_id            = var.apim_product.product_id
  api_management_name   = module.apim_service.name
  resource_group_name   = module.resource_group.name
  display_name          = var.apim_product.display_name
  approval_required     = try(var.apim_product.approval_required, null)
  published             = try(var.apim_product.published, null)
  subscription_required = try(var.apim_product.subscription_required, null)
  subscriptions_limit   = try(var.apim_product.subscriptions_limit, null)
  terms                 = try(var.apim_product.terms, null)
  description           = try(var.apim_product.description, null)
}

module "apim_product_api" {
  source              = "../../azure-terraform/modules/apim-product-api"
  resource_group_name = module.resource_group.name
  api_management_name = module.apim_service.name
  links               = var.apim_product_apis
}

module "apim_key_vault_role" {
  source = "../../azure-terraform/modules/role-assignments"
  assignments = {
    apim-kv = {
      scope                = module.key_vault.id
      principal_id         = var.apim_service.identity_principal_id
      role_definition_name = var.apim_key_vault_role_name
      principal_type       = "ServicePrincipal"
    }
  }
}

module "private_dns_records" {
  source = "../../azure-terraform/modules/private-dns-a-record"
  records = {
    for key, value in var.private_dns_records :
    key => merge(value, {
      records = [module.gateway_public_ip.ip_address]
    })
  }
  tags = local.common_tags
}

module "apim_diagnostics" {
  source                     = "../../azure-terraform/modules/diagnostic-settings"
  name                       = try(var.apim_diagnostics.name, "${local.name_prefix}-apim-diag")
  target_resource_id         = module.apim_service.id
  log_analytics_workspace_id = module.log_analytics.id
  logs                       = try(var.apim_diagnostics.logs, {})
  metrics                    = try(var.apim_diagnostics.metrics, {})
}

module "synapse_diagnostics" {
  source                     = "../../azure-terraform/modules/diagnostic-settings"
  name                       = try(var.synapse_diagnostics.name, "${local.name_prefix}-syn-diag")
  target_resource_id         = module.synapse_workspace.id
  log_analytics_workspace_id = module.log_analytics.id
  logs                       = try(var.synapse_diagnostics.logs, {})
  metrics                    = try(var.synapse_diagnostics.metrics, {})
}
