module "aks" {
  source                   = "Azure/avm-ptn-aks-production/azurerm"
  version                  = "0.5.0"
  name                     = "cmp-prod-cus-aks"
  location                 = var.location
  resource_group_name      = var.resource_group_name
  network                  = { node_subnet_id = var.node_subnet_id, pod_cidr = var.pod_cidr, service_cidr = var.service_cidr, dns_service_ip = var.dns_service_ip }
  kubernetes_version       = var.kubernetes_version
  network_policy           = "cilium"
  outbound_type            = "userDefinedRouting"
  default_node_pool_vm_sku = "Standard_D4d_v5"
  os_sku                   = "AzureLinux"
  os_disk_type             = "Managed"
  managed_identities       = { system_assigned = true }
  lock                     = { kind = "CanNotDelete" }
  enable_telemetry         = var.enable_telemetry
}
