# Azure Application Gateway (resource module). Resource in app-gateway.tf.
# WAF policy is passed by ID (firewall_policy_id); diagnostics are composed via
# terraform-azurerm-compeer-diagnostic-settings at the pattern layer.
# Interface mirrors terraform-azurerm-compeer-application-gateway.
