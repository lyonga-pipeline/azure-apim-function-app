locals {
  tags = merge({
    ManagedBy = "Terraform"
    IaCSource = "AVM+CompeerHCP"
    Phase     = "1"
    Workload  = "palo-alto"
  }, var.tags)

  interfaces = merge({}, [
    for appliance_key, appliance in var.appliances : {
      for interface_key, interface in appliance.interfaces : "${appliance_key}-${interface_key}" => merge(interface, {
        appliance_key = appliance_key
        interface_key = interface_key
      })
    }
  ]...)

  public_ips = {
    for key, interface in local.interfaces : key => interface.public_ip
    if try(interface.public_ip, null) != null
  }

  backend_pool_associations = {
    for key, interface in local.interfaces : key => interface
    if try(interface.load_balancer_backend_pool_id, null) != null
  }

  default_operational_contracts = {
    panorama_onboarding = {
      phase                = "Phase 1"
      implementation_state = "manual-now-terraform-phase-2"
      required_controls    = ["device registration", "template stack assignment", "device group assignment", "log forwarding profile"]
      notes                = "NET-12 remains a Panorama or Strata Cloud Manager workflow until the PAN-OS provider model is approved."
    }
    outbound_snat_policy = {
      phase                = "Phase 1"
      implementation_state = "manual-now-terraform-phase-2"
      required_controls    = ["internet SNAT policy", "no NAT for Compeer-to-Compeer paths", "route symmetry validation"]
      notes                = "NET-36 is firewall policy, not Azure infrastructure. Track evidence before workload go-live."
    }
    bootstrap_content = {
      phase                = "Phase 1"
      implementation_state = "operator-supplied-input"
      required_controls    = ["init-cfg.txt", "Panorama auth key or onboarding token", "license auth code handling", "no secrets committed to git"]
      notes                = "Terraform creates the account/share; bootstrap files are supplied through the approved secret/content workflow."
    }
  }
}

resource "azurerm_marketplace_agreement" "this" {
  for_each = var.marketplace_agreements

  publisher = each.value.publisher
  offer     = each.value.offer
  plan      = each.value.plan
}

module "bootstrap_storage" {
  source  = "app.terraform.io/Compeer-Financial-Services/compeer-storage-account/azurerm"
  version = "1.3.3"

  name                = var.bootstrap_storage_name
  resource_group_name = var.resource_group_name
  location            = var.location

  account_kind                      = "StorageV2"
  account_tier                      = "Standard"
  account_replication_type          = var.bootstrap_storage_replication_type
  min_tls_version                   = "TLS1_2"
  public_network_access_enabled     = var.bootstrap_storage_public_network_access_enabled
  shared_access_key_enabled         = var.bootstrap_storage_shared_access_key_enabled
  allow_nested_items_to_be_public   = false
  default_to_oauth_authentication   = true
  infrastructure_encryption_enabled = true
  network_rules                     = var.bootstrap_storage_network_rules
  blob_properties = {
    versioning_enabled              = true
    change_feed_enabled             = true
    last_access_time_enabled        = false
    delete_retention_days           = 14
    container_delete_retention_days = 14
  }
  tags = local.tags
}

resource "azurerm_storage_share" "bootstrap" {
  count = var.bootstrap_file_share == null ? 0 : 1

  name               = var.bootstrap_file_share.name
  storage_account_id = module.bootstrap_storage.id
  quota              = try(var.bootstrap_file_share.quota_gb, 50)
  enabled_protocol   = try(var.bootstrap_file_share.enabled_protocol, "SMB")
  metadata           = try(var.bootstrap_file_share.metadata, {})
}

module "bootstrap_storage_private_endpoint" {
  count   = var.bootstrap_storage_private_endpoint == null ? 0 : 1
  source  = "app.terraform.io/Compeer-Financial-Services/compeer-private-endpoint/azurerm"
  version = "1.0.5"

  name                          = "${var.bootstrap_storage_name}-${var.bootstrap_storage_private_endpoint.subresource_name}-pe"
  custom_network_interface_name = "${var.bootstrap_storage_name}-${var.bootstrap_storage_private_endpoint.subresource_name}-pe-nic"
  resource_group_name           = var.resource_group_name
  location                      = var.location
  subnet_id                     = var.bootstrap_storage_private_endpoint.subnet_id
  private_service_connections = [
    {
      name                           = "${var.bootstrap_storage_name}-${var.bootstrap_storage_private_endpoint.subresource_name}-psc"
      is_manual_connection           = false
      private_connection_resource_id = module.bootstrap_storage.id
      subresource_names              = [var.bootstrap_storage_private_endpoint.subresource_name]
    }
  ]
  private_dns_zone_group = length(var.bootstrap_storage_private_endpoint.private_dns_zone_ids) == 0 ? [] : [
    {
      name                 = "default"
      private_dns_zone_ids = var.bootstrap_storage_private_endpoint.private_dns_zone_ids
    }
  ]
  tags = local.tags
}

module "bootstrap_storage_rbac" {
  source  = "app.terraform.io/Compeer-Financial-Services/compeer-role-assignments/azurerm"
  version = "1.0.0"

  assignments = var.bootstrap_storage_role_assignments
}

module "public_ip" {
  for_each = local.public_ips
  source   = "app.terraform.io/Compeer-Financial-Services/compeer-public-ip/azurerm"
  version  = "1.0.0"

  name                    = each.value.name
  resource_group_name     = var.resource_group_name
  location                = var.location
  allocation_method       = try(each.value.allocation_method, "Static")
  sku                     = try(each.value.sku, "Standard")
  sku_tier                = try(each.value.sku_tier, "Regional")
  ip_version              = try(each.value.ip_version, "IPv4")
  domain_name_label       = try(each.value.domain_name_label, null)
  idle_timeout_in_minutes = try(each.value.idle_timeout_in_minutes, 4)
  public_ip_prefix_id     = try(each.value.public_ip_prefix_id, null)
  reverse_fqdn            = try(each.value.reverse_fqdn, null)
  zones                   = try(each.value.zones, ["1", "2", "3"])
  tags                    = local.tags
}

module "network_interface" {
  for_each = local.interfaces
  source   = "app.terraform.io/Compeer-Financial-Services/compeer-network-interface/azurerm"
  version  = "1.0.0"

  name                           = each.value.name
  resource_group_name            = var.resource_group_name
  location                       = var.location
  dns_servers                    = try(each.value.dns_servers, null)
  accelerated_networking_enabled = try(each.value.accelerated_networking_enabled, true)
  ip_forwarding_enabled          = try(each.value.ip_forwarding_enabled, true)
  ip_configurations = {
    (try(each.value.ip_configuration_name, "primary")) = {
      subnet_id                     = each.value.subnet_id
      private_ip_address_allocation = try(each.value.private_ip_address_allocation, "Static")
      private_ip_address            = try(each.value.private_ip_address, null)
      primary                       = true
      public_ip_address_id          = try(module.public_ip[each.key].id, null)
    }
  }
  tags = local.tags
}

resource "azurerm_network_interface_backend_address_pool_association" "this" {
  for_each = local.backend_pool_associations

  network_interface_id    = module.network_interface[each.key].id
  ip_configuration_name   = try(each.value.ip_configuration_name, "primary")
  backend_address_pool_id = each.value.load_balancer_backend_pool_id
}

resource "azurerm_linux_virtual_machine" "palo" {
  for_each = var.appliances

  name                            = each.value.name
  resource_group_name             = var.resource_group_name
  location                        = var.location
  size                            = each.value.vm_size
  admin_username                  = each.value.admin_username
  admin_password                  = try(var.admin_passwords[each.key], null)
  disable_password_authentication = try(each.value.disable_password_authentication, false)
  network_interface_ids           = [for interface_key in each.value.interface_order : module.network_interface["${each.key}-${interface_key}"].id]
  zone                            = try(each.value.zone, null)
  custom_data                     = try(each.value.custom_data, null) == null ? null : base64encode(each.value.custom_data)
  provision_vm_agent              = try(each.value.provision_vm_agent, true)
  allow_extension_operations      = try(each.value.allow_extension_operations, true)
  encryption_at_host_enabled      = try(each.value.encryption_at_host_enabled, true)
  secure_boot_enabled             = try(each.value.secure_boot_enabled, false)
  vtpm_enabled                    = try(each.value.vtpm_enabled, false)
  patch_mode                      = try(each.value.patch_mode, "ImageDefault")
  tags                            = local.tags

  os_disk {
    caching                   = try(each.value.os_disk.caching, "ReadWrite")
    storage_account_type      = try(each.value.os_disk.storage_account_type, "Premium_LRS")
    disk_size_gb              = try(each.value.os_disk.disk_size_gb, null)
    name                      = try(each.value.os_disk.name, null)
    write_accelerator_enabled = try(each.value.os_disk.write_accelerator_enabled, null)
    disk_encryption_set_id    = try(each.value.os_disk.disk_encryption_set_id, null)
  }

  dynamic "admin_ssh_key" {
    for_each = try(each.value.admin_ssh_keys, [])
    content {
      username   = admin_ssh_key.value.username
      public_key = admin_ssh_key.value.public_key
    }
  }

  dynamic "identity" {
    for_each = try(each.value.identity, null) == null ? [] : [each.value.identity]
    content {
      type         = identity.value.type
      identity_ids = try(identity.value.identity_ids, null)
    }
  }

  dynamic "boot_diagnostics" {
    for_each = try(each.value.boot_diagnostics, null) == null ? [] : [each.value.boot_diagnostics]
    content {
      storage_account_uri = try(boot_diagnostics.value.storage_account_uri, null)
    }
  }

  dynamic "plan" {
    for_each = try(each.value.plan, null) == null ? [] : [each.value.plan]
    content {
      name      = plan.value.name
      publisher = plan.value.publisher
      product   = plan.value.product
    }
  }

  dynamic "source_image_reference" {
    for_each = try(each.value.source_image_id, null) == null && try(each.value.source_image_reference, null) != null ? [each.value.source_image_reference] : []
    content {
      publisher = source_image_reference.value.publisher
      offer     = source_image_reference.value.offer
      sku       = source_image_reference.value.sku
      version   = source_image_reference.value.version
    }
  }

  source_image_id = try(each.value.source_image_id, null)

  depends_on = [azurerm_marketplace_agreement.this]

  lifecycle {
    precondition {
      condition     = try(each.value.source_image_id, null) != null || try(each.value.source_image_reference, null) != null
      error_message = "Each appliance must set source_image_id or source_image_reference."
    }
    precondition {
      condition     = try(each.value.source_image_id, null) == null || try(each.value.source_image_reference, null) == null
      error_message = "Set source_image_id or source_image_reference, not both."
    }
    precondition {
      condition = alltrue([
        for interface_key in each.value.interface_order : contains(keys(each.value.interfaces), interface_key)
      ])
      error_message = "interface_order must reference only keys from interfaces."
    }
  }
}

module "vm_diagnostics" {
  for_each = var.log_analytics_workspace_id == null ? {} : {
    for key, appliance in var.appliances : key => appliance
    if try(appliance.diagnostic_settings_enabled, true)
  }
  source  = "app.terraform.io/Compeer-Financial-Services/compeer-diagnostic-settings/azurerm"
  version = "1.0.0"

  name                       = "${each.value.name}-law"
  target_resource_id         = azurerm_linux_virtual_machine.palo[each.key].id
  log_analytics_workspace_id = var.log_analytics_workspace_id
  metrics = {
    all = { category = "AllMetrics" }
  }
}

module "operational_contracts" {
  source  = "app.terraform.io/Compeer-Financial-Services/compeer-operational-contracts/azurerm"
  version = "1.0.0"

  contracts = merge(local.default_operational_contracts, var.operational_contracts)
}
