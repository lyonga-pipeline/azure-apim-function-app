# Compeer Module Architecture
# Screenshot-Backed Implementation Appendix

## Scope

This appendix is based only on the screenshots under:

- `/Users/charleslyonga/Documents/azure-cloud/azure-apim-function-app/images/terraform-screenshots`
- `/Users/charleslyonga/Documents/azure-cloud/azure-apim-function-app/images/terraform-screenshots/ss`

It intentionally does **not** use the local module library under `azure-enterprise-terraform/terraform/modules`.

It is meant to complement:

- [Compeer-Module-Architecture-Enterprise-Reusability.docx](/Users/charleslyonga/Documents/azure-cloud/azure-apim-function-app/Compeer-Module-Architecture-Enterprise-Reusability.docx)

## How To Read This Appendix

For each screenshot-backed module, this appendix includes:

1. `Observed screenshot pattern`
   A short HCL snippet reconstructed from what was visible in the screenshots.

2. `Interpretation`
   What that pattern means architecturally.

3. `Recommended implementation pattern`
   A concrete example of how to reshape the module contract.

4. `Why this improves reuse and reduces drift`
   The enterprise reason the recommendation is safer for HCP Terraform and cross-team consumption.

## Common Target Patterns

These are the recurring implementation patterns that showed up across the screenshot reviews.

### Pattern A: Use `object(...)` for singleton nested blocks

Instead of this:

```hcl
dynamic "identity" {
  for_each = var.identity != null ? [var.identity] : []
  content {
    type         = identity.value.type
    identity_ids = identity.value.identity_ids
  }
}
```

Prefer this variable contract:

```hcl
variable "identity" {
  type = object({
    type         = string
    identity_ids = optional(list(string))
  })
  default = null
}
```

And this implementation:

```hcl
dynamic "identity" {
  for_each = var.identity == null ? [] : [var.identity]
  content {
    type         = identity.value.type
    identity_ids = try(identity.value.identity_ids, null)
  }
}
```

Why:

- clearer consumer contract
- fewer fake list wrappers
- easier examples and documentation

### Pattern B: Use `map(object(...))` for repeated named children

Instead of this:

```hcl
variable "subscriptions" {
  type = list(object({
    name = string
  }))
}
```

Prefer this:

```hcl
variable "subscriptions" {
  type = map(object({
    name = string
  }))
  default = {}
}
```

And:

```hcl
resource "example_child" "this" {
  for_each = var.subscriptions
  name     = each.key
}
```

Why:

- stable keys reduce order churn
- HCP plans stay cleaner
- easier partial ownership and imports

### Pattern C: Separate core resources from attachments and policy

Instead of one module owning the resource plus every child concern:

```hcl
resource "azurerm_key_vault" "this" { ... }
resource "azurerm_key_vault_access_policy" "this" { ... }
resource "azurerm_private_endpoint" "this" { ... }
resource "azurerm_monitor_diagnostic_setting" "this" { ... }
```

Prefer:

- one core module for the resource lifecycle
- companion modules for policy, attachments, diagnostics, or extensions

Why:

- fewer ownership collisions
- less drift from neighboring teams
- smaller blast radius per workspace

### Pattern D: Treat `ignore_changes` as an exception

If used, document:

- why it exists
- whether it is a provider bug, Azure-side mutation, or split ownership
- what signal would let the team remove it later

Without that, `ignore_changes` often hides drift instead of solving it.

---

## Supplemental Context

## Repository: `compeer-base-infrastructure-nlz`
## Module/Context: import-based remediation in push details

### Observed screenshot pattern

```hcl
import {
  to = module.base_infra.module.compeer_private_dns_zones["openai"].azurerm_private_dns_zone.private_dns_zone
  id = "/subscriptions/.../providers/Microsoft.Network/privateDnsZones/privatelink.openai.azure.com"
}

import {
  to = module.base_infra.module.compeer_private_dns_zones["search"].azurerm_private_dns_zone_virtual_network_link.private_dns_zone_virtual_network_link
  id = "/subscriptions/.../virtualNetworkLinks/..."
}
```

### Interpretation

- the estate is actively reconciling existing resources into Terraform state
- drift is not theoretical here; remediation is already happening
- networking, private DNS, and subnet attachment ownership are likely not fully clean yet

### Recommended implementation pattern

```hcl
module "private_dns_zone" {
  source = "app/terraform/private-dns-zone"

  zones = {
    openai = {
      name = "privatelink.openai.azure.com"
    }
  }
}

module "private_dns_link" {
  source = "app/terraform/private-dns-zone-link"

  links = {
    openai_hub = {
      zone_id                 = module.private_dns_zone.zone_ids["openai"]
      virtual_network_id      = module.hub_vnet.id
      registration_enabled    = false
    }
  }
}
```

### Why this improves reuse and reduces drift

- zones and links are separate ownership units
- imports become simpler because each module owns one lifecycle boundary
- workspace ownership is easier to explain and audit

---

## Screenshot Set 1: Root `terraform-screenshots`

## Repository: `terraform-azurerm-compeer-application-insights`
## Module: Application Insights

### Observed screenshot pattern

```hcl
resource "azurerm_application_insights" "application_insights" {
  name                                  = var.name
  resource_group_name                   = var.resource_group_name
  location                              = var.location
  application_type                      = var.application_type
  retention_in_days                     = var.retention_in_days
  sampling_percentage                   = var.sampling_percentage
  workspace_id                          = var.workspace_id
  tags                                  = var.tags
}
```

### Interpretation

- good core resource boundary
- most commonly used resource arguments are already exposed
- the module is close to reusable, but still looks like a raw resource wrapper rather than an enterprise-ready productized module

### Recommended implementation pattern

```hcl
variable "diagnostics" {
  type = object({
    workspace_id = string
  })
  default = null
}

module "application_insights" {
  source = "app/terraform/application-insights-core"

  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location
  application_type    = var.application_type
  workspace_id        = var.workspace_id
  tags                = var.tags
}

module "application_insights_diagnostics" {
  source = "app/terraform/diagnostic-setting"
  count  = var.diagnostics == null ? 0 : 1

  target_resource_id = module.application_insights.id
  workspace_id       = var.diagnostics.workspace_id
}
```

### Why this improves reuse and reduces drift

- keeps the monitoring component lifecycle clean
- avoids forcing every team into the same diagnostics pattern
- makes it easier to change observability ownership later

---

## Repository: `terraform-azurerm-compeer-event-grid`
## Module: Event Grid Topic and Subscription

### Observed screenshot pattern

```hcl
resource "azurerm_eventgrid_topic" "main" {
  name                = var.eventgrid_topic_name
  resource_group_name = var.resource_group_name
}

resource "azurerm_eventgrid_event_subscription" "subscription" {
  for_each = local.eventgrid_subscription
  scope    = azurerm_eventgrid_topic.main.id

  dynamic "azure_function_endpoint" { ... }
  dynamic "webhook_endpoint" { ... }
}

/*
This module is not covering `subject_filter`, `advanced_filter`, `delivery_identity`, `delivery_property`.
*/
```

### Interpretation

- topic lifecycle and subscription lifecycle are coupled
- the module is flexible, but incomplete
- if one team owns the topic and another owns subscribers, this module will create drift and coordination problems

### Recommended implementation pattern

```hcl
module "eventgrid_topic" {
  source = "app/terraform/eventgrid-topic"

  name                = var.topic_name
  resource_group_name = var.resource_group_name
  location            = var.location
}

module "eventgrid_subscriptions" {
  source = "app/terraform/eventgrid-subscription"

  subscriptions = {
    orders_webhook = {
      scope = module.eventgrid_topic.id
      webhook_endpoint = {
        url = "https://example.org/events"
      }
      subject_filter = {
        subject_begins_with = "/orders/"
      }
    }
  }
}
```

### Why this improves reuse and reduces drift

- topic teams and subscriber teams can move independently
- subscriptions can target existing topics
- `map(object(...))` keeps subscription identities stable in state

---

## Repository: `terraform-azurerm-compeer-keyvault-managed-hsm`
## Module: Key Vault Managed HSM

### Observed screenshot pattern

```hcl
resource "azurerm_key_vault_managed_hardware_security_module" "managed_hsm" {
  name                               = var.name
  resource_group_name                = var.resource_group_name
  location                           = var.location
  admin_object_ids                   = var.admin_object_ids
  security_domain_key_vault_certificate_ids = var.security_domain_key_vault_certificate_ids

  dynamic "network_acls" {
    for_each = var.network_acls != null ? [var.network_acls] : []
    content {
      default_action = network_acls.value.default_action
      bypass         = network_acls.value.bypass
    }
  }
}
```

### Interpretation

- focused module
- strong candidate to keep
- main improvement is interface cleanup, not architectural rewrite

### Recommended implementation pattern

```hcl
variable "network_acls" {
  type = object({
    default_action = string
    bypass         = string
  })
  default = null
}

variable "diagnostics" {
  type = object({
    workspace_id = string
  })
  default = null
}
```

### Why this improves reuse and reduces drift

- singleton configuration stays readable
- teams can turn on diagnostics without polluting the core contract
- the module remains small and trustworthy

---

## Repository: `terraform-azurerm-compeer-network-security-group`
## Module: Network Security Group

### Observed screenshot pattern

```hcl
resource "azurerm_network_security_group" "network_security_group" {
  dynamic "security_rule" {
    for_each = var.security_rule
    content {
      name                       = security_rule.value.name
      source_port_ranges         = lookup(security_rule.value, "source_port_ranges", null)
      destination_port_ranges    = lookup(security_rule.value, "destination_port_ranges", null)
      source_application_security_group_ids      = lookup(security_rule.value, "source_application_security_group_ids", null)
      destination_application_security_group_ids = lookup(security_rule.value, "destination_application_security_group_ids", null)
    }
  }
}

resource "azurerm_subnet_network_security_group_association" "network_security_group_association" {
  subnet_id                 = var.subnet_id
  network_security_group_id = azurerm_network_security_group.network_security_group.id
}
```

### Interpretation

- NSG rules are modeled reasonably
- subnet attachment is bundled into the same lifecycle
- that is risky in enterprise networking because subnet ownership and rule ownership often differ

### Recommended implementation pattern

```hcl
module "nsg" {
  source = "app/terraform/network-security-group"

  rules = {
    allow_https = {
      priority                   = 100
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      destination_port_ranges    = ["443"]
      source_address_prefix      = "*"
      destination_address_prefix = "*"
    }
  }
}

module "nsg_subnet_association" {
  source = "app/terraform/network-security-group-association"

  subnet_id = var.subnet_id
  nsg_id    = module.nsg.id
}
```

### Why this improves reuse and reduces drift

- lets the network team own subnet attachment independently
- rules can evolve without fighting subnet lifecycle
- stable rule keys reduce plan churn

---

## Repository: `terraform-azurerm-compeer-storage-account`
## Module: Storage Account

### Observed screenshot pattern

```hcl
resource "azurerm_storage_account" "storage_account" {
  name                     = var.name
  account_tier             = var.account_tier
  account_replication_type = var.account_replication_type

  dynamic "identity" { ... }
  dynamic "customer_managed_key" { ... }
  dynamic "blob_properties" { ... }
  dynamic "share_properties" { ... }

  lifecycle {
    ignore_changes = [identity]
  }
}

resource "azurerm_storage_container" "storage_container" { ... }
resource "azurerm_storage_blob" "blob_storage" { ... }
resource "azurerm_storage_queue" "storage_queue" { ... }
resource "azurerm_storage_table" "tables" { ... }
resource "azurerm_storage_share" "file_share" { ... }
```

### Interpretation

- this repo owns too many different lifecycles
- account, containers, queues, tables, blobs, and shares do not change at the same cadence
- flattening and nested child creation increase drift risk in HCP state

### Recommended implementation pattern

```hcl
module "storage_account_core" {
  source = "app/terraform/storage-account-core"

  name                     = var.name
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = var.account_tier
  account_replication_type = var.account_replication_type
}

module "storage_containers" {
  source = "app/terraform/storage-container"

  storage_account_name = module.storage_account_core.name
  containers = {
    app = {
      access_type = "private"
    }
  }
}
```

### Why this improves reuse and reduces drift

- separates control-plane lifecycle from data-plane objects
- lets application teams own child resources without reowning the account
- removes the need for large flattening locals and broad `ignore_changes`

---

## Repository: `terraform-azurerm-compeer-vnet-peering`
## Module: VNet Peering

### Observed screenshot pattern

```hcl
resource "azurerm_virtual_network_peering" "peering" {
  name                      = var.peering_name
  resource_group_name       = var.rg_name
  virtual_network_name      = var.vnet_name
  remote_virtual_network_id = var.remote_virtual_network_id
  allow_virtual_network_access = var.allow_virtual_network_access
  allow_forwarded_traffic      = var.allow_forwarded_traffic
  allow_gateway_transit        = var.allow_gateway_transit
  use_remote_gateways          = var.use_remote_gateways
}
```

### Interpretation

- small, clean module
- good boundary
- main improvement area is validation and better directional examples

### Recommended implementation pattern

```hcl
variable "allow_gateway_transit" {
  type    = bool
  default = false
}

variable "use_remote_gateways" {
  type    = bool
  default = false

  validation {
    condition     = !(var.allow_gateway_transit && var.use_remote_gateways)
    error_message = "allow_gateway_transit and use_remote_gateways cannot both be true in the same peering direction."
  }
}
```

### Why this improves reuse and reduces drift

- catches invalid combinations before apply
- avoids failed plans and manual correction loops
- keeps a good small module small

---

## Repository: `terraform-azurerm-compeer-windows-function-app`
## Module: Windows Function App

### Observed screenshot pattern

```hcl
resource "azurerm_windows_function_app" "windows_function_app" {
  location            = var.location
  name                = var.name
  resource_group_name = var.resource_group_name
  service_plan_id     = var.service_plan_id

  dynamic "site_config" {
    for_each = var.site_config
    content {
      always_on  = lookup(site_config.value, "always_on", null)
      ftps_state = lookup(site_config.value, "ftps_state", null)

      dynamic "application_stack" { ... }
      dynamic "ip_restriction" { ... }
      dynamic "scm_ip_restriction" { ... }
    }
  }

  dynamic "backup" { ... }
  dynamic "connection_string" { ... }
  dynamic "identity" { ... }
}
```

### Interpretation

- very broad feature coverage
- good direction for reusability
- current input model is hard for teams to consume consistently because many singleton blocks are represented as list-driven dynamic blocks

### Recommended implementation pattern

```hcl
variable "site_config" {
  type = object({
    always_on  = optional(bool)
    ftps_state = optional(string)
    application_stack = optional(object({
      dotnet_version              = optional(string)
      use_dotnet_isolated_runtime = optional(bool)
      powershell_core_version     = optional(string)
    }))
    ip_restrictions = optional(map(object({
      action                    = string
      priority                  = number
      ip_address                = optional(string)
      virtual_network_subnet_id = optional(string)
    })), {})
  })
  default = null
}
```

### Why this improves reuse and reduces drift

- cleaner examples
- stable named IP restriction entries
- less consumer confusion about which blocks are one-to-one vs one-to-many

---

## Repository: `terraform-azurerm-test-availabilityset-sql`
## Module: Availability Set SQL workload stack

### Observed screenshot pattern

```hcl
resource "azurerm_availability_set" "availability" { ... }
resource "azurerm_network_interface" "nic" { ... }
resource "azurerm_managed_disk" "data_disk" { ... }
resource "azurerm_windows_virtual_machine" "windows_vm" { ... }
resource "azurerm_mssql_virtual_machine" "mssql_virtual_machine" { ... }
resource "azurerm_virtual_machine_extension" "join-domain" { ... }
```

### Interpretation

- this is a solution stack, not a reusable base module
- it crosses too many lifecycle boundaries
- AD join credentials and SQL guest configuration should not be hardwired into a base reusable artifact

### Recommended implementation pattern

```hcl
module "sql_vm_platform" {
  source = "app/terraform/sql-vm-solution"

  vm_id               = module.windows_vm.id
  data_disk_ids       = module.data_disks.ids
  availability_set_id = module.availability_set.id
}
```

Where `sql-vm-solution` consumes:

- `windows-vm-core`
- `network-interface`
- `managed-disk`
- `sql-vm-registration`
- optional `domain-join-extension`

### Why this improves reuse and reduces drift

- keeps reusable modules small
- lets the solution layer own the composition
- minimizes blast radius when one child concern changes

---

## Screenshot Set 2: `terraform-screenshots/ss`

## Repository: `terraform-azurerm-compeer-apim`
## Module: API Management service

### Observed screenshot pattern

```hcl
dynamic "policy" {
  for_each = var.policy != null ? [var.policy] : []
  content {
    xml_content = lookup(policy.value, "xml_content", null)
    xml_link    = lookup(policy.value, "xml_link", null)
  }
}

dynamic "protocols" {
  for_each = var.protocols != null ? [var.protocols] : []
  content {
    enable_http2 = lookup(proxy.value, "enable_http2", null)
  }
}

resource "azurerm_monitor_diagnostic_setting" "main" {
  lifecycle {
    ignore_changes = [log_analytics_destination_type]
  }
}
```

### Interpretation

- good repo separation from API and product child modules
- heavy singleton-as-list modeling
- diagnostics drift is being suppressed rather than clearly owned

### Recommended implementation pattern

```hcl
variable "policy" {
  type = object({
    xml_content = optional(string)
    xml_link    = optional(string)
  })
  default = null
}

variable "protocols" {
  type = object({
    enable_http2 = optional(bool)
  })
  default = null
}

variable "diagnostics" {
  type = object({
    workspace_id                    = string
    log_analytics_destination_type  = optional(string, "Dedicated")
  })
  default = null
}
```

### Why this improves reuse and reduces drift

- base APIM service stays understandable
- singleton contracts become much easier to document
- diagnostics configuration becomes explicit desired state instead of hidden drift tolerance

---

## Repository: `terraform-azurerm-compeer-actiongroup`
## Module: Monitor Action Group

### Observed screenshot pattern

```hcl
resource "azurerm_monitor_action_group" "this" {
  name                = var.action_group_name
  resource_group_name = var.resource_group_name
  short_name          = var.action_group_short_name

  dynamic "email_receiver" {
    for_each = var.actiongrp_email_receiver
  }

  dynamic "automation_runbook_receiver" {
    for_each = var.actiongrp_automation_runbook_receiver
  }
}
```

### Interpretation

- good narrow boundary
- receiver support is useful, but still partial
- visible example values looked too close to live webhook material

### Recommended implementation pattern

```hcl
variable "receivers" {
  type = object({
    email = optional(map(object({
      email_address           = string
      use_common_alert_schema = optional(bool, true)
    })), {})
    automation_runbook = optional(map(object({
      automation_account_id   = string
      runbook_name            = string
      webhook_resource_id     = string
      service_uri_secret_name = optional(string)
      is_global_runbook       = optional(bool, false)
    })), {})
  })
  default = {}
}
```

### Why this improves reuse and reduces drift

- gives receivers a predictable hierarchy
- makes it easier to extend receiver families later
- encourages secret indirection instead of embedding webhook details in examples

---

## Repository: `terraform-azure-compeer-synapse`
## Module: Synapse workspace bootstrap

### Observed screenshot pattern

```hcl
resource "azurerm_storage_data_lake_gen2_filesystem" "data_lake_gen2_fs" {
  name               = var.data_lake_gen2_fs_name
  storage_account_id = data.azurerm_storage_account.storage_account.id
}

resource "azurerm_synapse_workspace" "synapse_workspace" {
  name                                 = var.synapse_workspace_name
  storage_data_lake_gen2_filesystem_id = azurerm_storage_data_lake_gen2_filesystem.data_lake_gen2_fs.id
  sql_administrator_login              = var.sql_admin_login
  sql_administrator_login_password     = var.sql_admin_password
}
```

### Interpretation

- workspace creation is coupled to filesystem creation
- reasonable bootstrap pattern
- not flexible enough if storage ownership is centralized

### Recommended implementation pattern

```hcl
variable "workspace_storage" {
  type = object({
    create_filesystem = optional(bool, false)
    storage_account_id = string
    filesystem_name    = string
    existing_filesystem_id = optional(string)
  })
}

locals {
  filesystem_id = var.workspace_storage.existing_filesystem_id != null
    ? var.workspace_storage.existing_filesystem_id
    : azurerm_storage_data_lake_gen2_filesystem.this[0].id
}
```

### Why this improves reuse and reduces drift

- works for both platform-owned storage and app-owned storage
- avoids forcing one ownership model on every team
- reduces re-imports when filesystems already exist

---

## Repository: `terraform-azurerm-compeer-apim-api`
## Module: APIM API

### Observed screenshot pattern

```hcl
resource "azurerm_api_management_api" "api" {
  api_management_name = var.apim_name
  resource_group_name = var.resource_group_name
  name                = var.api_name
  path                = var.path
  protocols           = var.protocols

  dynamic "contact" { ... }
  dynamic "import"  { ... }
  dynamic "license" { ... }
  dynamic "oauth2_authorization" { ... }
}
```

### Interpretation

- strong module decomposition
- better singleton modeling than some of the larger repos
- main risk is pulling adjacent APIM concerns into the API repo over time

### Recommended implementation pattern

```hcl
variable "import" {
  type = object({
    content_format = string
    content_value  = string
  })
  default = null
}

variable "authorization" {
  type = object({
    authorization_server_name = optional(string)
    openid_provider_name      = optional(string)
    scope                     = optional(string)
  })
  default = null
}
```

### Why this improves reuse and reduces drift

- keeps API onboarding clear
- avoids forcing ownership of authorization server resources into the same repo
- makes API imports deterministic and easy to review

---

## Repository: `terraform-azurerm-compeer-apim-product`
## Module: APIM Product

### Observed screenshot pattern

```hcl
resource "azurerm_api_management_product" "apim_product" {
  api_management_name    = var.apim_name
  display_name           = var.display_name
  product_id             = var.product_id
  approval_required      = var.approval_required
  subscription_required  = var.subscription_required
  subscription_limit     = var.subscriptions_limit
}
```

### Interpretation

- clean and focused
- good candidate to keep small
- likely needs companion modules for product-to-API attachment and group relationships

### Recommended implementation pattern

```hcl
module "apim_product" {
  source = "app/terraform/apim-product"
  # product core only
}

module "apim_product_api_attachment" {
  source = "app/terraform/apim-product-api"

  product_api_links = {
    orders = {
      product_id = module.apim_product.product_id
      api_name   = module.orders_api.name
    }
  }
}
```

### Why this improves reuse and reduces drift

- product lifecycle stays independent
- API onboarding does not have to re-own product configuration
- cleaner HCP workspace boundaries

---

## Repository: `terraform-azurerm-compeer-app-gateway`
## Module: Application Gateway

### Observed screenshot pattern

```hcl
resource "azurerm_application_gateway" "main" {
  dynamic "backend_address_pool" { ... }
  dynamic "backend_http_settings" { ... }
  dynamic "http_listener" { ... }
  dynamic "request_routing_rule" { ... }
  dynamic "authentication_certificate" { ... }
  dynamic "trusted_root_certificate" { ... }
  dynamic "ssl_policy" { ... }
  dynamic "ssl_certificate" { ... }
  dynamic "url_path_map" { ... }
  dynamic "redirect_configuration" { ... }
  dynamic "custom_error_configuration" { ... }
  dynamic "waf_configuration" { ... }

  lifecycle {
    ignore_changes = [tags]
  }
}

resource "azurerm_monitor_diagnostic_setting" "main" {
  lifecycle {
    ignore_changes = [log_analytics_destination_type]
  }
}
```

### Interpretation

- very capable module
- also the clearest example of a module whose interface can become too broad to use safely across teams
- list-heavy nested configuration and ignore rules will make drift hard to reason about at scale

### Recommended implementation pattern

```hcl
variable "listeners" {
  type = map(object({
    frontend_ip_configuration_name = string
    frontend_port_name             = string
    protocol                       = string
    host_names                     = optional(list(string), [])
    ssl_certificate_name           = optional(string)
    firewall_policy_id             = optional(string)
  }))
  default = {}
}

variable "routing_rules" {
  type = map(object({
    rule_type                  = string
    listener_name              = string
    backend_pool_name          = optional(string)
    backend_http_settings_name = optional(string)
    url_path_map_name          = optional(string)
    redirect_configuration_name = optional(string)
  }))
  default = {}
}
```

### Why this improves reuse and reduces drift

- stable named objects reduce reordering noise
- consumers can reason about listeners and rules as named entities
- the module becomes easier to publish with approved usage patterns

---

## Repository: `terraform-azurerm-compeer-keyvault`
## Module: Key Vault

### Observed screenshot pattern

```hcl
resource "azurerm_key_vault" "keyvault" {
  name                       = var.name
  enabled_for_deployment     = var.enabled_for_deployment
  purge_protection_enabled   = var.purge_protection_enabled
  public_network_access_enabled = var.public_network_access_enabled

  dynamic "access_policy" {
    for_each = var.access_policies != null ? [var.access_policies] : []
    content {
      tenant_id               = access_policy.value.tenant_id
      object_id               = access_policy.value.object_id
      key_permissions         = access_policy.value.key_permissions
      secret_permissions      = access_policy.value.secret_permissions
      certificate_permissions = access_policy.value.certificate_permissions
    }
  }

  dynamic "network_acls" { ... }
}
```

### Interpretation

- the core vault lifecycle is good
- inline access policies are the drift risk
- this is where platform and application ownership will most likely collide

### Recommended implementation pattern

```hcl
module "key_vault_core" {
  source = "app/terraform/key-vault-core"

  name                          = var.name
  resource_group_name           = var.resource_group_name
  location                      = var.location
  enable_rbac_authorization     = true
  public_network_access_enabled = false
}

module "key_vault_role_assignments" {
  source = "app/terraform/key-vault-rbac"

  assignments = {
    app_reader = {
      scope                = module.key_vault_core.id
      role_definition_name = "Key Vault Secrets User"
      principal_id         = var.app_principal_id
    }
  }
}
```

### Why this improves reuse and reduces drift

- vault lifecycle and access lifecycle can move independently
- RBAC is easier to scale across teams than embedding all access policies into one module
- fewer surprise updates to the vault resource when app teams change permissions

---

## Repository: `terraform-azurerm-compeer-nat-gateway`
## Module: NAT Gateway

### Observed screenshot pattern

```hcl
resource "azurerm_nat_gateway" "nat-gateway" {
  name                = var.nat_gateway_name
  location            = var.location
  resource_group_name = var.resource_group_name
  sku_name            = var.sku_name
  #zones              = var.availability_zones
}

resource "azurerm_public_ip" "pip" {
  count = var.public_ip_count
}

resource "azurerm_nat_gateway_public_ip_association" "associate-pip" {
  count = var.public_ip_count
}

resource "azurerm_subnet_nat_gateway_association" "associate-subnet" {
  count     = length(var.subnet_ids)
  subnet_id = var.subnet_ids[count.index]
}
```

### Interpretation

- small, understandable module
- zones look half-finished in the screenshoted repo
- public IP creation and subnet association are coupled into one lifecycle

### Recommended implementation pattern

```hcl
variable "public_ip_ids" {
  type    = set(string)
  default = []
}

resource "azurerm_nat_gateway_public_ip_association" "this" {
  for_each = var.public_ip_ids

  nat_gateway_id       = azurerm_nat_gateway.this.id
  public_ip_address_id = each.value
}

resource "azurerm_subnet_nat_gateway_association" "this" {
  for_each = var.subnet_ids

  subnet_id      = each.value
  nat_gateway_id = azurerm_nat_gateway.this.id
}
```

### Why this improves reuse and reduces drift

- teams can attach existing public IPs instead of recreating them
- `for_each` gives stable resource identity
- subnet attachment can be split later if ownership requires it

---

## Repository: `terraform-azurerm-compeer-private-endpoint`
## Module: Private Endpoint

### Observed screenshot pattern

```hcl
resource "azurerm_private_endpoint" "private_endpoint" {
  name                = var.name
  resource_group_name = var.resource_group_name
  subnet_id           = var.subnet_id

  dynamic "private_service_connection" {
    for_each = var.private_service_connections
  }

  dynamic "private_dns_zone_group" {
    for_each = var.private_dns_zone_group != null ? var.private_dns_zone_group : []
  }

  dynamic "ip_configuration" {
    for_each = var.ip_configurations != null ? var.ip_configurations : []
  }

  lifecycle {
    ignore_changes = [
      private_service_connection[0].request_message,
      private_service_connection[0].private_connection_resource_alias,
      tags
    ]
  }
}
```

### Interpretation

- strong core feature coverage
- but the current contract mixes connection details, DNS group details, and optional IP configuration into one broad resource wrapper
- `ignore_changes` suggests parts of the contract are not fully stable

### Recommended implementation pattern

```hcl
variable "service_connection" {
  type = object({
    name                              = string
    is_manual_connection              = bool
    private_connection_resource_id    = optional(string)
    private_connection_resource_alias = optional(string)
    subresource_names                 = optional(list(string), [])
    request_message                   = optional(string)
  })

  validation {
    condition = (
      (var.service_connection.private_connection_resource_id != null) !=
      (var.service_connection.private_connection_resource_alias != null)
    )
    error_message = "Specify either private_connection_resource_id or private_connection_resource_alias, but not both."
  }
}
```

### Why this improves reuse and reduces drift

- makes the most important mutually exclusive fields explicit
- avoids ambiguous updates and provider-side mutations
- lets DNS integration be optional and more safely owned by central networking if needed

---

## Modules Mentioned In The Word Doc But Not Backed By The Provided Screenshot Sets

The following module families are mentioned in the Word document, but were not visible in the screenshot sets I used for this appendix:

- Windows VM
- MSSQL Database
- Load Balancer
- Log Analytics
- Private DNS
- Container Agent
- Network Interface
- Windows Web App
- Networking (VNet)
- APIM Backend

Because you asked me to base the analysis on the screenshots you provided here, I did **not** create screenshot-backed implementation entries for those modules in this appendix.

If you want, I can produce a second appendix for those modules too, but I would want either:

- screenshots for those specific repos/modules, or
- explicit permission to base that appendix on the local code or the Word document text alone

## Final Practical Guidance

If this appendix is going back into the architecture document, the highest-value pattern changes to implement first are:

1. split core resources from attachments, diagnostics, policies, and child objects
2. replace `list(object(...))` with `map(object(...))` for repeated named children
3. replace singleton list wrappers with `object(...)` plus `null`
4. document or remove every `ignore_changes`
5. publish curated examples for the large edge modules: APIM, App Gateway, Windows Function App, Key Vault, and Private Endpoint

That combination will do more to improve HCP Terraform stability and cross-team reuse than simply adding more variables to already-large modules.
