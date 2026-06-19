package compeer.lz

deny[msg] {
  resource := input.resource_changes[_]
  is_create_or_update(resource.change.actions)
  not exempt_resource_type(resource.type)
  not has_required_tags(resource.change.after.tags)
  msg := sprintf("%s is missing one or more required enterprise tags", [resource.address])
}

deny[msg] {
  resource := input.resource_changes[_]
  is_create_or_update(resource.change.actions)
  location := lower(resource.change.after.location)
  location != "global"
  not allowed_location(location)
  msg := sprintf("%s uses unapproved Azure location %s", [resource.address, location])
}

deny[msg] {
  resource := input.resource_changes[_]
  resource.type == "azurerm_public_ip"
  resource.change.actions[_] == "create"
  msg := sprintf("%s creates a public IP address; public exposure requires explicit platform approval", [resource.address])
}

deny[msg] {
  resource := input.resource_changes[_]
  resource.type == "azurerm_storage_account"
  is_create_or_update(resource.change.actions)
  resource.change.after.public_network_access_enabled
  msg := sprintf("%s enables public network access on a storage account", [resource.address])
}

deny[msg] {
  resource := input.resource_changes[_]
  resource.type == "azurerm_key_vault"
  is_create_or_update(resource.change.actions)
  resource.change.after.public_network_access_enabled
  msg := sprintf("%s enables public network access on a Key Vault", [resource.address])
}

deny[msg] {
  resource := input.resource_changes[_]
  is_app_service_type(resource.type)
  is_create_or_update(resource.change.actions)
  not resource.change.after.https_only
  msg := sprintf("%s must enforce HTTPS-only traffic", [resource.address])
}

deny[msg] {
  resource := input.resource_changes[_]
  is_app_service_type(resource.type)
  is_create_or_update(resource.change.actions)
  resource.change.after.public_network_access_enabled
  msg := sprintf("%s enables public network access on an App Service resource", [resource.address])
}

is_create_or_update(actions) {
  actions[_] == "create"
}

is_create_or_update(actions) {
  actions[_] == "update"
}

allowed_location(location) {
  data.net_new_lz.allowed_locations[_] == location
}

is_app_service_type(resource_type) {
  resource_type == "azurerm_windows_function_app"
}

is_app_service_type(resource_type) {
  resource_type == "azurerm_linux_function_app"
}

is_app_service_type(resource_type) {
  resource_type == "azurerm_windows_web_app"
}

is_app_service_type(resource_type) {
  resource_type == "azurerm_linux_web_app"
}

has_required_tags(tags) {
  required := {tag | tag := data.net_new_lz.required_tags[_]}
  present := {lower(tag) | tags[tag]}
  missing := required - present
  count(missing) == 0
}

exempt_resource_type(resource_type) {
  resource_type == data.net_new_lz.exempt_resource_types[_]
}
