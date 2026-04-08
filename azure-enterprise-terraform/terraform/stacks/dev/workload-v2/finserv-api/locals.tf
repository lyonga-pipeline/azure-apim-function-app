locals {
  api_spec_path               = var.api_spec_path != null ? abspath(var.api_spec_path) : abspath("${path.root}/../../../api-spec.yml")
  shared_services_cmk_enabled = var.enable_app_configuration || var.enable_service_bus
  shared_identity_outputs     = var.use_shared_identity_services ? local.identity_outputs : null
  demo_windows_vm_enabled     = var.enable_demo_windows_vm
  demo_windows_vm_password_valid = trimspace(coalesce(var.demo_windows_vm_admin_password, "")) != "" && (
    length(var.demo_windows_vm_admin_password) >= 14 &&
    can(regex("[A-Z]", var.demo_windows_vm_admin_password)) &&
    can(regex("[a-z]", var.demo_windows_vm_admin_password)) &&
    can(regex("[0-9]", var.demo_windows_vm_admin_password)) &&
    can(regex("[^A-Za-z0-9]", var.demo_windows_vm_admin_password))
  )

  effective_app_identity = var.use_shared_identity_services ? {
    id           = local.shared_identity_outputs.shared_identity_ids[var.shared_identity_workload_identity_key]
    client_id    = local.shared_identity_outputs.shared_identity_client_ids[var.shared_identity_workload_identity_key]
    principal_id = local.shared_identity_outputs.shared_identity_principal_ids[var.shared_identity_workload_identity_key]
    name         = local.shared_identity_outputs.shared_identity_names[var.shared_identity_workload_identity_key]
    } : {
    id           = module.app_identity[0].id
    client_id    = module.app_identity[0].client_id
    principal_id = module.app_identity[0].principal_id
    name         = "uai-${var.environment}-${var.application}"
  }

  runtime_principal_id = local.effective_app_identity.principal_id

  shared_services_cmk_key_id = var.use_shared_identity_services ? local.shared_identity_outputs.shared_services_cmk_key_id : try(module.shared_services_cmk[0].id, null)

  app_subnet_nsg_rules = [
    {
      name                       = "allow-vnet-inbound"
      priority                   = 100
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "*"
      source_address_prefix      = "VirtualNetwork"
      destination_address_prefix = "VirtualNetwork"
    },
    {
      name                       = "deny-internet-inbound"
      priority                   = 200
      direction                  = "Inbound"
      access                     = "Deny"
      protocol                   = "*"
      source_address_prefix      = "Internet"
      destination_address_prefix = "*"
    },
  ]

  integration_subnet_nsg_rules = [
    {
      name                       = "allow-azuremonitor-outbound"
      priority                   = 100
      direction                  = "Outbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      destination_port_range     = "443"
      source_address_prefix      = "*"
      destination_address_prefix = "AzureMonitor"
    },
    {
      name                       = "allow-storage-outbound"
      priority                   = 110
      direction                  = "Outbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      destination_port_range     = "443"
      source_address_prefix      = "*"
      destination_address_prefix = "Storage"
    },
    {
      name                       = "allow-keyvault-outbound"
      priority                   = 120
      direction                  = "Outbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      destination_port_range     = "443"
      source_address_prefix      = "*"
      destination_address_prefix = "AzureKeyVault"
    },
    {
      name                       = "allow-sql-outbound"
      priority                   = 130
      direction                  = "Outbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      destination_port_range     = "1433"
      source_address_prefix      = "*"
      destination_address_prefix = "Sql"
    },
    {
      name                       = "deny-internet-outbound"
      priority                   = 400
      direction                  = "Outbound"
      access                     = "Deny"
      protocol                   = "*"
      source_address_prefix      = "*"
      destination_address_prefix = "Internet"
    },
  ]

  data_subnet_nsg_rules = [
    {
      name                       = "allow-vnet-inbound"
      priority                   = 100
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "*"
      source_address_prefix      = "VirtualNetwork"
      destination_address_prefix = "VirtualNetwork"
    },
    {
      name                       = "deny-internet-inbound"
      priority                   = 200
      direction                  = "Inbound"
      access                     = "Deny"
      protocol                   = "*"
      source_address_prefix      = "Internet"
      destination_address_prefix = "*"
    },
  ]

  spoke_subnets = merge(
    {
      app = {
        address_prefixes = [var.app_subnet_cidr]
        nsg_rules        = local.app_subnet_nsg_rules
      }
      integration = {
        address_prefixes = [var.integration_subnet_cidr]
        nsg_rules        = local.integration_subnet_nsg_rules
        delegations = [
          {
            name = "appservice-delegation"
            service_delegation = {
              name    = "Microsoft.Web/serverFarms"
              actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
            }
          }
        ]
      }
      data = {
        address_prefixes = [var.data_subnet_cidr]
        nsg_rules        = local.data_subnet_nsg_rules
      }
      private-endpoints = {
        address_prefixes                  = [var.private_endpoints_subnet_cidr]
        private_endpoint_network_policies = "Disabled"
        nsg_rules                         = []
      }
    },
    var.enable_apim ? {
      apim = {
        address_prefixes = [var.apim_subnet_cidr]
        nsg_rules        = []
      }
    } : {},
  )

  # App data storage only needs blob private endpoint — it stores application data,
  # not Function runtime content. File/queue/table endpoints are on the host storage.
  storage_private_endpoint_targets = {
    blob = {
      dns_key           = "blob"
      subresource_names = ["blob"]
    }
  }

  # Function host storage requires all four sub-resources for VNet-integrated
  # Functions with WEBSITE_CONTENTOVERVNET=1. The runtime reads/writes blob for
  # package content, queue for trigger state, table for lease metadata, and file
  # for legacy deployment paths.
  function_host_storage_private_endpoint_targets = var.enable_function_app ? {
    blob = {
      dns_key           = "blob"
      subresource_names = ["blob"]
    }
    file = {
      dns_key           = "file"
      subresource_names = ["file"]
    }
    queue = {
      dns_key           = "queue"
      subresource_names = ["queue"]
    }
    table = {
      dns_key           = "table"
      subresource_names = ["table"]
    }
  } : {}

  baseline_workload_role_assignments = merge(
    {
      function_keyvault_reader = {
        scope                = module.key_vault.id
        role_definition_name = "Key Vault Secrets User"
        principal_id         = local.runtime_principal_id
      }
    },
    var.assign_storage_blob_data_contributor ? {
      function_storage_blob_contributor = {
        scope                = module.storage_account.account_id
        role_definition_name = "Storage Blob Data Contributor"
        principal_id         = local.runtime_principal_id
      }
    } : {},
    var.assign_storage_queue_data_contributor ? {
      function_storage_queue_contributor = {
        scope                = module.storage_account.account_id
        role_definition_name = "Storage Queue Data Contributor"
        principal_id         = local.runtime_principal_id
      }
    } : {},
    var.enable_app_configuration ? {
      function_appconfig_reader = {
        scope                = module.app_configuration[0].id
        role_definition_name = "App Configuration Data Reader"
        principal_id         = local.runtime_principal_id
      }
    } : {},
    var.enable_service_bus ? {
      function_servicebus_sender = {
        scope                = module.service_bus[0].id
        role_definition_name = "Azure Service Bus Data Sender"
        principal_id         = local.runtime_principal_id
      }
      function_servicebus_receiver = {
        scope                = module.service_bus[0].id
        role_definition_name = "Azure Service Bus Data Receiver"
        principal_id         = local.runtime_principal_id
      }
    } : {},
  )

  additional_workload_role_assignments = {
    for name, assignment in var.additional_workload_role_assignments :
    name => {
      scope                                  = assignment.scope
      role_definition_name                   = assignment.role_definition_name
      principal_id                           = coalesce(try(assignment.principal_id, null), local.runtime_principal_id)
      principal_type                         = try(assignment.principal_type, null)
      condition                              = try(assignment.condition, null)
      condition_version                      = try(assignment.condition_version, null)
      delegated_managed_identity_resource_id = try(assignment.delegated_managed_identity_resource_id, null)
      skip_service_principal_aad_check       = try(assignment.skip_service_principal_aad_check, false)
    }
  }

  demo_windows_vm_role_assignments = local.demo_windows_vm_enabled ? tomap({
    demo_windows_vm_keyvault_secrets_user = {
      scope                = module.key_vault.id
      role_definition_name = "Key Vault Secrets User"
      principal_id         = module.demo_windows_vm[0].identity_principal_id
    }
    demo_windows_vm_storage_blob_contributor = {
      scope                = module.storage_account.account_id
      role_definition_name = "Storage Blob Data Contributor"
      principal_id         = module.demo_windows_vm[0].identity_principal_id
    }
  }) : tomap({})

  workload_role_assignments = merge(
    local.baseline_workload_role_assignments,
    local.demo_windows_vm_role_assignments,
    local.additional_workload_role_assignments,
  )

  encryption_role_assignments = !var.use_shared_identity_services && local.shared_services_cmk_enabled ? {
    app_identity_key_crypto = {
      scope                = module.key_vault.id
      role_definition_name = "Key Vault Crypto Service Encryption User"
      principal_id         = local.effective_app_identity.principal_id
    }
  } : {}
}
