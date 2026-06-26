package compeer.lz

deny contains msg if {
	resource := input.resource_changes[_]
	is_create_or_update(resource.change.actions)
	not exempt_resource_type(resource.type)
	tags := object.get(resource.change.after, "tags", null)
	tags != null
	not has_required_tags(tags)
	msg := sprintf("%s is missing one or more required enterprise tags", [resource.address])
}

deny contains msg if {
	resource := input.resource_changes[_]
	is_create_or_update(resource.change.actions)
	location := lower(resource.change.after.location)
	location != "global"
	not allowed_location(location)
	msg := sprintf("%s uses unapproved Azure location %s", [resource.address, location])
}

deny contains msg if {
	resource := input.resource_changes[_]
	resource.type == "azurerm_public_ip"
	resource.change.actions[_] == "create"
	msg := sprintf("%s creates a public IP address; public exposure requires explicit platform approval", [resource.address])
}

deny contains msg if {
	resource := input.resource_changes[_]
	resource.type == "azurerm_storage_account"
	is_create_or_update(resource.change.actions)
	object.get(resource.change.after, "public_network_access_enabled", false)
	msg := sprintf("%s enables public network access on a storage account", [resource.address])
}

deny contains msg if {
	resource := input.resource_changes[_]
	resource.type == "azurerm_storage_account"
	is_create_or_update(resource.change.actions)
	tls_version := object.get(resource.change.after, "min_tls_version", "")
	tls_version != ""
	not approved_storage_tls_version(tls_version)
	msg := sprintf("%s must use an approved storage minimum TLS version", [resource.address])
}

deny contains msg if {
	resource := input.resource_changes[_]
	resource.type == "azurerm_storage_account"
	is_create_or_update(resource.change.actions)
	object.get(resource.change.after, "shared_access_key_enabled", false)
	msg := sprintf("%s enables shared access keys; storage should prefer identity-based access", [resource.address])
}

deny contains msg if {
	resource := input.resource_changes[_]
	resource.type == "azurerm_storage_account"
	is_create_or_update(resource.change.actions)
	object.get(resource.change.after, "allow_nested_items_to_be_public", false)
	msg := sprintf("%s allows nested blob items to be public", [resource.address])
}

deny contains msg if {
	resource := input.resource_changes[_]
	resource.type == "azurerm_storage_account"
	is_create_or_update(resource.change.actions)
	object.get(resource.change.after, "infrastructure_encryption_enabled", true) == false
	msg := sprintf("%s must keep infrastructure encryption enabled", [resource.address])
}

deny contains msg if {
	resource := input.resource_changes[_]
	resource.type == "azurerm_key_vault"
	is_create_or_update(resource.change.actions)
	object.get(resource.change.after, "public_network_access_enabled", false)
	msg := sprintf("%s enables public network access on a Key Vault", [resource.address])
}

deny contains msg if {
	resource := input.resource_changes[_]
	resource.type == "azurerm_key_vault"
	is_create_or_update(resource.change.actions)
	object.get(resource.change.after, "enable_rbac_authorization", true) == false
	msg := sprintf("%s must use RBAC authorization", [resource.address])
}

deny contains msg if {
	resource := input.resource_changes[_]
	resource.type == "azurerm_key_vault"
	is_create_or_update(resource.change.actions)
	object.get(resource.change.after, "purge_protection_enabled", true) == false
	msg := sprintf("%s must keep purge protection enabled", [resource.address])
}

deny contains msg if {
	resource := input.resource_changes[_]
	resource.type == "azurerm_key_vault"
	is_create_or_update(resource.change.actions)
	retention_days := object.get(resource.change.after, "soft_delete_retention_days", 90)
	retention_days < 90
	msg := sprintf("%s must use 90-day soft delete retention", [resource.address])
}

deny contains msg if {
	resource := input.resource_changes[_]
	resource.type == "azurerm_mssql_server"
	is_create_or_update(resource.change.actions)
	object.get(resource.change.after, "public_network_access_enabled", false)
	msg := sprintf("%s enables public network access on SQL Server", [resource.address])
}

deny contains msg if {
	resource := input.resource_changes[_]
	resource.type == "azurerm_mssql_server"
	is_create_or_update(resource.change.actions)
	tls_version := object.get(resource.change.after, "minimum_tls_version", "")
	tls_version != ""
	not approved_app_tls_version(tls_version)
	msg := sprintf("%s must use SQL minimum TLS 1.2 or higher", [resource.address])
}

deny contains msg if {
	resource := input.resource_changes[_]
	resource.type == "azurerm_mssql_server"
	is_create_or_update(resource.change.actions)
	object.get(resource.change.after, "azuread_authentication_only", true) == false
	msg := sprintf("%s should use Microsoft Entra-only authentication", [resource.address])
}

deny contains msg if {
	resource := input.resource_changes[_]
	is_app_service_type(resource.type)
	is_create_or_update(resource.change.actions)
	object.get(resource.change.after, "https_only", true) == false
	msg := sprintf("%s must enforce HTTPS-only traffic", [resource.address])
}

deny contains msg if {
	resource := input.resource_changes[_]
	is_app_service_type(resource.type)
	is_create_or_update(resource.change.actions)
	object.get(resource.change.after, "public_network_access_enabled", false)
	msg := sprintf("%s enables public network access on an App Service resource", [resource.address])
}

deny contains msg if {
	resource := input.resource_changes[_]
	is_app_service_type(resource.type)
	is_create_or_update(resource.change.actions)
	site_config := app_site_config(resource)
	tls_version := object.get(site_config, "minimum_tls_version", "")
	tls_version != ""
	not approved_app_tls_version(tls_version)
	msg := sprintf("%s must use application minimum TLS 1.2 or higher", [resource.address])
}

deny contains msg if {
	resource := input.resource_changes[_]
	is_app_service_type(resource.type)
	is_create_or_update(resource.change.actions)
	site_config := app_site_config(resource)
	tls_version := object.get(site_config, "scm_minimum_tls_version", "")
	tls_version != ""
	not approved_app_tls_version(tls_version)
	msg := sprintf("%s must use SCM minimum TLS 1.2 or higher", [resource.address])
}

deny contains msg if {
	resource := input.resource_changes[_]
	is_app_service_type(resource.type)
	is_create_or_update(resource.change.actions)
	object.get(resource.change.after, "ftp_publish_basic_authentication_enabled", false)
	msg := sprintf("%s enables FTP basic publishing authentication", [resource.address])
}

deny contains msg if {
	resource := input.resource_changes[_]
	is_app_service_type(resource.type)
	is_create_or_update(resource.change.actions)
	object.get(resource.change.after, "webdeploy_publish_basic_authentication_enabled", false)
	msg := sprintf("%s enables WebDeploy basic publishing authentication", [resource.address])
}

deny contains msg if {
	resource := input.resource_changes[_]
	requires_managed_identity(resource.type)
	is_create_or_update(resource.change.actions)
	not has_managed_identity(resource.change.after)
	msg := sprintf("%s must use managed identity for the net-new landing-zone pattern", [resource.address])
}

deny contains msg if {
	resource := input.resource_changes[_]
	requires_diagnostics(resource.type)
	is_create_or_update(resource.change.actions)
	not diagnostic_setting_in_plan
	msg := sprintf("%s creates or updates a resource type that requires diagnostic settings in the root composition", [resource.address])
}

deny contains msg if {
	source := module_sources[_]
	not approved_module_source(source)
	msg := sprintf("module source %s is not approved for the net-new landing-zone path", [source])
}

is_create_or_update(actions) if {
	actions[_] == "create"
}

is_create_or_update(actions) if {
	actions[_] == "update"
}

is_delete(actions) if {
	actions[_] == "delete"
}

allowed_location(location) if {
	data.net_new_lz.allowed_locations[_] == location
}

is_app_service_type(resource_type) if {
	data.net_new_lz.app_service_resource_types[_] == resource_type
}

has_required_tags(tags) if {
	required := {lower(tag) | tag := data.net_new_lz.required_tags[_]}
	present := {lower(tag) | tags[tag]}
	missing := required - present
	count(missing) == 0
}

exempt_resource_type(resource_type) if {
	resource_type == data.net_new_lz.exempt_resource_types[_]
}

approved_app_tls_version(version) if {
	data.net_new_lz.approved_app_tls_versions[_] == version
}

approved_storage_tls_version(version) if {
	data.net_new_lz.approved_storage_tls_versions[_] == version
}

requires_diagnostics(resource_type) if {
	data.net_new_lz.diagnostics_required_resource_types[_] == resource_type
}

requires_managed_identity(resource_type) if {
	data.net_new_lz.managed_identity_required_resource_types[_] == resource_type
}

has_managed_identity(resource) if {
	identity := object.get(resource, "identity", null)
	identity_type := lower(identity_type_value(identity))
	identity_type != ""
	identity_type != "none"
}

identity_type_value(identity) := identity_type if {
	is_array(identity)
	count(identity) > 0
	identity_type := object.get(identity[0], "type", "")
}

identity_type_value(identity) := identity_type if {
	is_object(identity)
	identity_type := object.get(identity, "type", "")
}

diagnostic_setting_in_plan if {
	resource := input.resource_changes[_]
	resource.type == "azurerm_monitor_diagnostic_setting"
	not is_delete(resource.change.actions)
}

module_sources contains source if {
	some path, value
	walk(input.configuration.root_module, [path, value])
	is_object(value)
	calls := object.get(value, "module_calls", {})
	call := calls[_]
	source := object.get(call, "source", "")
	source != ""
}

approved_module_source(source) if {
	prefix := data.net_new_lz.approved_module_source_prefixes[_]
	startswith(source, prefix)
}

app_site_config(resource) := site_config if {
	site_configs := object.get(resource.change.after, "site_config", [])
	count(site_configs) > 0
	site_config := site_configs[0]
}

app_site_config(resource) := site_config if {
	site_config := object.get(resource.change.after, "site_config", {})
	not is_array(site_config)
}
