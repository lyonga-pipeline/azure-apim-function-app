resource "azurerm_network_interface_application_security_group_association" "this" {
  for_each = var.associations

  network_interface_id          = each.value.network_interface_id
  application_security_group_id = each.value.application_security_group_id
}
