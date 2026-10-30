# PHASE2 NEW: reuse the vault owner's existing system topic and hosted handler.
# No passwords, secret payloads, function keys or privileged credentials enter Terraform.
data "azurerm_eventgrid_system_topic" "vault" {
  for_each            = { for key, value in var.secret_rotations : key => value if !value.create_system_topic }
  name                = each.value.system_topic_name
  resource_group_name = each.value.system_topic_resource_group
}
resource "azurerm_eventgrid_system_topic" "vault" {
  for_each            = { for key, value in var.secret_rotations : key => value if value.create_system_topic }
  name                = each.value.system_topic_name
  resource_group_name = each.value.system_topic_resource_group
  location            = each.value.system_topic_location
  source_resource_id  = each.value.vault_id
  topic_type          = "Microsoft.KeyVault.vaults"
  tags                = var.tags
  identity { type = "SystemAssigned" }
}
resource "terraform_data" "topic_contract" {
  for_each = var.secret_rotations
  lifecycle {
    precondition {
      condition = each.value.create_system_topic ? true : (
        lower(data.azurerm_eventgrid_system_topic.vault[each.key].source_resource_id) == lower(each.value.vault_id) &&
        data.azurerm_eventgrid_system_topic.vault[each.key].topic_type == "Microsoft.KeyVault.vaults" &&
        try(data.azurerm_eventgrid_system_topic.vault[each.key].identity[0].principal_id == each.value.topic_principal_id, false)
      )
      error_message = "Reused Event Grid topic must actually belong to this vault and expose the declared SystemAssigned principal."
    }
  }
}
resource "azurerm_role_assignment" "rotation_writer" {
  for_each             = var.secret_rotations
  scope                = each.value.vault_id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = each.value.function_principal_id
  principal_type       = "ServicePrincipal"
  depends_on           = [terraform_data.topic_contract]
}
resource "azurerm_role_assignment" "dead_letter_writer" {
  for_each             = var.secret_rotations
  scope                = "${each.value.dead_letter_storage_id}/blobServices/default/containers/${each.value.dead_letter_container_name}"
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = local.topic_principal_ids[each.key]
  principal_type       = "ServicePrincipal"
  depends_on           = [terraform_data.topic_contract]
}
resource "azurerm_eventgrid_system_topic_event_subscription" "rotation" {
  for_each              = var.secret_rotations
  name                  = each.value.name
  system_topic          = each.value.system_topic_name
  resource_group_name   = each.value.system_topic_resource_group
  included_event_types  = ["Microsoft.KeyVault.SecretNearExpiry"]
  event_delivery_schema = "EventGridSchema"
  azure_function_endpoint {
    function_id          = each.value.function_id
    max_events_per_batch = 1
  }
  advanced_filter {
    string_in {
      key    = "data.ObjectName"
      values = sort(tolist(each.value.secret_names))
    }
  }
  retry_policy {
    event_time_to_live    = 1440
    max_delivery_attempts = 30
  }
  dead_letter_identity { type = "SystemAssigned" }
  storage_blob_dead_letter_destination {
    storage_account_id          = each.value.dead_letter_storage_id
    storage_blob_container_name = each.value.dead_letter_container_name
  }
  depends_on = [azurerm_role_assignment.rotation_writer, azurerm_role_assignment.dead_letter_writer, azurerm_eventgrid_system_topic.vault]
}
