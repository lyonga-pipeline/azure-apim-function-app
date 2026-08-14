resource "azurerm_app_service_environment" "app_service_environment" {
  count = var.create_v3 ? 0 : 1

  name                = var.name
  resource_group_name = var.resource_group_name

  # NOTE: a /24 or larger CIDR is required. Once associated with an ASE this size cannot be changed.
  subnet_id = var.subnet_id

  dynamic "cluster_setting" {
    for_each = var.cluster_setting
    content {
      name  = cluster_setting.value.name
      value = cluster_setting.value.value
    }
  }

  internal_load_balancing_mode = var.internal_load_balancing_mode
  pricing_tier                 = var.pricing_tier
  front_end_scale_factor       = var.front_end_scale_factor

  /* NOTE: allowed_user_ip_cidrs The addresses that will be used for all outbound traffic 
  from your App Service Environment to the internet to avoid asymmetric routing challenge. 
  If you're routing the traffic on premises, these addresses are your NATs or gateway IPs. 
  If you want to route the App Service Environment outbound traffic through an NVA, 
  the egress address is the public IP of the NVA. 
  Please visit Create your ASE with the egress addresses
  (https://learn.microsoft.com/en-us/azure/app-service/environment/forced-tunnel-support#add-your-own-ips-to-the-ase-azure-sql-firewall)
  */
  allowed_user_ip_cidrs = var.allowed_user_ip_cidrs
  tags                  = var.tags
  timeouts {
    create = "4h"
    update = "4h"
    read   = "4h"
    delete = "4h"
  }
}

resource "azurerm_app_service_environment_v3" "service_environment_v3" {
  count               = var.create_v3 ? 1 : 0
  name                = var.name
  resource_group_name = var.resource_group_name

  /*
  NOTE: a /24 or larger CIDR is required. Once associated with an ASE this size cannot be changed.
  This Subnet requires a delegation to Microsoft.Web/hostingEnvironments
  */
  subnet_id = var.subnet_id

  allow_new_private_endpoint_connections = var.allow_new_private_endpoint_connections

  /*
  If this block is specified it must contain the FrontEndSSLCipherSuiteOrder setting, 
  with the value TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384,TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256.
  */
  dynamic "cluster_setting" {
    for_each = var.cluster_setting
    content {
      name  = cluster_setting.value.name
      value = cluster_setting.value.value
    }
  }

  # dedicated_host_count = var.dedicated_host_count

  /*
  Setting this value will provision 2 Physical Hosts for your App Service Environment V3,
  this is done at additional cost, please be aware of the pricing commitment in the 
  General Availability Notes(https://techcommunity.microsoft.com/t5/apps-on-azure/announcing-app-service-environment-v3-ga/ba-p/2517990)
  */
  zone_redundant = var.zone_redundant

  internal_load_balancing_mode = var.internal_load_balancing_mode_v3

  timeouts {
    create = "4h"
    update = "4h"
    read   = "4h"
    delete = "4h"
  }
}