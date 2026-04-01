variable "environment" {
  type        = string
  description = "Environment tag."
}

variable "subscription_id" {
  type        = string
  description = "Landing zone subscription id for the workload deployment."

  validation {
    condition     = !can(regex("^0{8}-0{4}-0{4}-0{4}-0{12}$", var.subscription_id))
    error_message = "subscription_id still uses the placeholder all-zero value. Set the real workload subscription id in dev.tfvars before planning or applying."
  }
}

variable "subscription_catalog_entry_key" {
  type        = string
  description = "Entry key in the subscriptions catalog for this stack."
  default     = "nonprod_finserv_api"
}

variable "use_subscriptions_state" {
  type        = bool
  description = "Validate the stack subscription against the central subscriptions state."
  default     = true
}

variable "subscriptions_state_rg" {
  type        = string
  description = "Resource group hosting the subscriptions stack state."
  default     = "rg-tfstate-dev"
}

variable "subscriptions_state_sa" {
  type        = string
  description = "Storage account hosting the subscriptions stack state."
  default     = "demotest822e"
}

variable "subscriptions_state_container" {
  type        = string
  description = "Container hosting the subscriptions stack state."
  default     = "deploy-container"
}

variable "subscriptions_state_key" {
  type        = string
  description = "State blob key for the subscriptions stack."
  default     = "global/subscriptions.tfstate"
}

variable "subscriptions_state_subscription_id" {
  type        = string
  description = "Subscription containing the subscriptions stack remote state."
  default     = null

  validation {
    condition     = var.subscriptions_state_subscription_id == null || !can(regex("^0{8}-0{4}-0{4}-0{4}-0{12}$", var.subscriptions_state_subscription_id))
    error_message = "subscriptions_state_subscription_id still uses the placeholder all-zero value. Set the real platform-state subscription id or leave it null."
  }
}

variable "location" {
  type        = string
  description = "Azure region."
}

variable "application" {
  type        = string
  description = "Application code."
}

variable "created_by" {
  type        = string
  description = "Provisioning source tag."
  default     = "terraform"
}

variable "workload_resource_group_name" {
  type        = string
  description = "Workload resource group name."
}

variable "spoke_vnet_name" {
  type        = string
  description = "Workload spoke VNet name."
}

variable "spoke_address_space" {
  type        = list(string)
  description = "Workload spoke CIDR ranges."
}

variable "app_subnet_cidr" {
  type        = string
  description = "Application subnet CIDR."
  default     = "10.20.1.0/24"
}

variable "integration_subnet_cidr" {
  type        = string
  description = "Integration subnet CIDR."
  default     = "10.20.2.0/24"
}

variable "data_subnet_cidr" {
  type        = string
  description = "Data subnet CIDR."
  default     = "10.20.3.0/24"
}

variable "private_endpoints_subnet_cidr" {
  type        = string
  description = "Private endpoints subnet CIDR."
  default     = "10.20.10.0/24"
}

variable "apim_subnet_cidr" {
  type        = string
  description = "Optional APIM subnet CIDR."
  default     = "10.20.20.0/24"
}

variable "storage_account_name" {
  type        = string
  description = "Storage account name."
}

variable "key_vault_name" {
  type        = string
  description = "Key Vault name."
}

variable "function_app_name" {
  type        = string
  description = "Function App name."
}

variable "enable_function_app" {
  type        = bool
  description = "Deploy the Function App and backing App Service plan."
  default     = true
}

variable "enable_apim" {
  type        = bool
  description = "Enable API Management."
  default     = false
}

variable "api_management_name" {
  type        = string
  description = "API Management name."
  default     = null
}

variable "publisher_name" {
  type        = string
  description = "APIM publisher name."
  default     = null
}

variable "publisher_email" {
  type        = string
  description = "APIM publisher email."
  default     = null
}

variable "api_name" {
  type        = string
  description = "API name in APIM."
  default     = "finserv-api"
}

variable "api_display_name" {
  type        = string
  description = "API display name."
  default     = "FinServ API"
}

variable "api_path" {
  type        = string
  description = "API path."
  default     = "finserv"
}

variable "api_spec_path" {
  type        = string
  description = "Optional absolute or relative path to the OpenAPI file."
  default     = null
}

variable "enable_service_bus" {
  type        = bool
  description = "Enable Service Bus."
  default     = true
}

variable "service_bus_name" {
  type        = string
  description = "Service Bus namespace name."
  default     = null
}

variable "enable_app_configuration" {
  type        = bool
  description = "Enable App Configuration."
  default     = true
}

variable "app_configuration_name" {
  type        = string
  description = "App Configuration name."
  default     = null
}

variable "enable_sql" {
  type        = bool
  description = "Enable Azure SQL."
  default     = false
}

variable "sql_server_name" {
  type        = string
  description = "Azure SQL server name."
  default     = null
}

variable "sql_databases" {
  type        = map(any)
  description = "Databases to create."
  default     = {}
}

variable "sql_aad_admin_login" {
  type        = string
  description = "Azure AD admin login for SQL."
  default     = null
}

variable "sql_aad_admin_object_id" {
  type        = string
  description = "Azure AD admin object id for SQL."
  default     = null
}

variable "enable_container_registry" {
  type        = bool
  description = "Enable ACR."
  default     = false
}

variable "container_registry_name" {
  type        = string
  description = "Azure Container Registry name."
  default     = null
}

variable "container_registry_replica_locations" {
  type        = list(string)
  description = "Secondary Azure regions for ACR geo-replication."
  default     = ["centralus"]
}

variable "service_plan_sku" {
  type        = string
  description = "Function App service plan SKU."
  default     = "EP1"
}

variable "function_public_network_access_enabled" {
  type        = bool
  description = "Allow public access to the Function App."
  default     = false
}

variable "enable_function_private_endpoint" {
  type        = bool
  description = "Create a private endpoint for the Function App."
  default     = true
}

variable "function_app_settings" {
  type        = map(string)
  description = "Additional Function App settings."
  default     = {}
}

variable "assign_storage_blob_data_contributor" {
  type        = bool
  description = "Grant the workload managed identity Storage Blob Data Contributor on the workload storage account."
  default     = true
}

variable "assign_storage_queue_data_contributor" {
  type        = bool
  description = "Grant the workload managed identity Storage Queue Data Contributor on the workload storage account."
  default     = false
}

variable "enable_demo_windows_vm" {
  type        = bool
  description = "Deploy a smallest-practical demo Windows VM in the spoke VNet to validate private access and managed identity patterns."
  default     = false
}

variable "demo_windows_vm_name" {
  type        = string
  description = "Name for the optional demo Windows VM."
  default     = null
}

variable "demo_windows_vm_size" {
  type        = string
  description = "SKU for the optional demo Windows VM."
  default     = "Standard_B1ms"
}

variable "demo_windows_vm_subnet_key" {
  type        = string
  description = "Spoke subnet key for the optional demo Windows VM."
  default     = "app"

  validation {
    condition     = contains(["app", "integration", "data"], var.demo_windows_vm_subnet_key)
    error_message = "demo_windows_vm_subnet_key must be one of app, integration, or data."
  }
}

variable "demo_windows_vm_admin_username" {
  type        = string
  description = "Local admin username for the optional demo Windows VM."
  default     = "azureadmin"
}

variable "demo_windows_vm_admin_password" {
  type        = string
  description = "Local admin password for the demo Windows VM. Required when enable_demo_windows_vm is true."
  default     = null
  sensitive   = true

  validation {
    condition = var.demo_windows_vm_admin_password == null || (
      length(var.demo_windows_vm_admin_password) >= 14 &&
      can(regex("[A-Z]", var.demo_windows_vm_admin_password)) &&
      can(regex("[a-z]", var.demo_windows_vm_admin_password)) &&
      can(regex("[0-9]", var.demo_windows_vm_admin_password)) &&
      can(regex("[^A-Za-z0-9]", var.demo_windows_vm_admin_password))
    )
    error_message = "demo_windows_vm_admin_password must be at least 14 characters and include upper, lower, numeric, and special characters."
  }
}

variable "demo_windows_vm_os_disk_storage_account_type" {
  type        = string
  description = "OS disk SKU for the optional demo Windows VM."
  default     = "Standard_LRS"
}

variable "additional_workload_role_assignments" {
  type = map(object({
    scope                                  = string
    role_definition_name                   = string
    principal_id                           = optional(string)
    principal_type                         = optional(string)
    condition                              = optional(string)
    condition_version                      = optional(string)
    delegated_managed_identity_resource_id = optional(string)
    skip_service_principal_aad_check       = optional(bool, false)
  }))
  description = "Additional RBAC assignments merged with the baseline workload identity access. principal_id defaults to the workload managed identity when omitted."
  default     = {}
}

variable "enable_azuredevops" {
  type        = bool
  description = "Create Azure DevOps project and repository resources."
  default     = false
}

variable "create_azuredevops_project" {
  type        = bool
  description = "Create a new Azure DevOps project."
  default     = false
}

variable "azuredevops_project_name" {
  type        = string
  description = "Azure DevOps project name."
  default     = null
}

variable "azuredevops_repository_name" {
  type        = string
  description = "Azure DevOps repository name."
  default     = null
}

variable "azuredevops_default_branch" {
  type        = string
  description = "Azure DevOps default branch reference."
  default     = "refs/heads/main"
}

variable "azuredevops_org_service_url" {
  type        = string
  description = "Azure DevOps organization service URL. Required only when Azure DevOps resources are enabled."
  default     = null
}

variable "azuredevops_personal_access_token" {
  type        = string
  description = "Azure DevOps personal access token. Required only when Azure DevOps resources are enabled."
  default     = null
  sensitive   = true
}

variable "use_shared_identity_services" {
  type        = bool
  description = "Consume shared identity and CMK resources from the platform identity stack."
  default     = true
}

variable "business_owner" {
  type        = string
  description = "Business owner tag."
}

variable "source_repo" {
  type        = string
  description = "Source repository tag."
  default     = "azure-apim-function-app"
}

variable "terraform_workspace" {
  type        = string
  description = "Terraform workspace or stack name."
  default     = "workload-finserv-api"
}

variable "recovery_tier" {
  type        = string
  description = "Recovery method tag."
  default     = "rubrik"
}

variable "cost_center" {
  type        = string
  description = "Cost center tag."
}

variable "compliance_boundary" {
  type        = string
  description = "Compliance boundary tag."
  default     = "finserv"
}

variable "creation_date_utc" {
  type        = string
  description = "Optional immutable creation timestamp tag."
  default     = null
}

variable "last_modified_utc" {
  type        = string
  description = "Optional last modified timestamp tag."
  default     = null
}

variable "additional_tags" {
  type        = map(string)
  description = "Additional tags."
  default     = {}
}

variable "connectivity_state_rg" {
  type        = string
  description = "Connectivity state resource group."
}

variable "platform_state_subscription_id" {
  type        = string
  description = "Optional shared subscription id hosting platform remote state backends."
  default     = null

  validation {
    condition     = var.platform_state_subscription_id == null || !can(regex("^0{8}-0{4}-0{4}-0{4}-0{12}$", var.platform_state_subscription_id))
    error_message = "platform_state_subscription_id still uses the placeholder all-zero value. Set the real platform-state subscription id or leave it null."
  }
}

variable "connectivity_state_sa" {
  type        = string
  description = "Connectivity state storage account."
}

variable "connectivity_state_container" {
  type        = string
  description = "Connectivity state container."
  default     = "deploy-container"
}

variable "connectivity_state_key" {
  type        = string
  description = "Connectivity state key."
}

variable "connectivity_state_subscription_id" {
  type        = string
  description = "Optional connectivity remote state subscription id override."
  default     = null

  validation {
    condition     = var.connectivity_state_subscription_id == null || !can(regex("^0{8}-0{4}-0{4}-0{4}-0{12}$", var.connectivity_state_subscription_id))
    error_message = "connectivity_state_subscription_id still uses the placeholder all-zero value. Set the real connectivity-state subscription id or leave it null."
  }
}

variable "management_state_rg" {
  type        = string
  description = "Management state resource group."
}

variable "management_state_sa" {
  type        = string
  description = "Management state storage account."
}

variable "management_state_container" {
  type        = string
  description = "Management state container."
  default     = "deploy-container"
}

variable "management_state_key" {
  type        = string
  description = "Management state key."
}

variable "management_state_subscription_id" {
  type        = string
  description = "Optional management remote state subscription id override."
  default     = null

  validation {
    condition     = var.management_state_subscription_id == null || !can(regex("^0{8}-0{4}-0{4}-0{4}-0{12}$", var.management_state_subscription_id))
    error_message = "management_state_subscription_id still uses the placeholder all-zero value. Set the real management-state subscription id or leave it null."
  }
}

variable "identity_state_rg" {
  type        = string
  description = "Identity state resource group."
  default     = null
}

variable "identity_state_sa" {
  type        = string
  description = "Identity state storage account."
  default     = null
}

variable "identity_state_container" {
  type        = string
  description = "Identity state container."
  default     = "deploy-container"
}

variable "identity_state_key" {
  type        = string
  description = "Identity state key."
  default     = null
}

variable "identity_state_subscription_id" {
  type        = string
  description = "Optional identity remote state subscription id override."
  default     = null

  validation {
    condition     = var.identity_state_subscription_id == null || !can(regex("^0{8}-0{4}-0{4}-0{4}-0{12}$", var.identity_state_subscription_id))
    error_message = "identity_state_subscription_id still uses the placeholder all-zero value. Set the real identity-state subscription id or leave it null."
  }
}

variable "shared_identity_workload_identity_key" {
  type        = string
  description = "Logical key of the shared identity output to use for workload service encryption."
  default     = "workload_runtime"
}
