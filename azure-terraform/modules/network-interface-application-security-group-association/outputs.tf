output "ids" {
  value = {
    for key, value in azurerm_network_interface_application_security_group_association.this :
    key => value.id
  }
}
