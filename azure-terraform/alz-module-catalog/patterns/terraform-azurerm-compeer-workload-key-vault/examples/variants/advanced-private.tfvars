# Team B: HSM-backed keys in Key Vault Premium (not a dedicated Managed HSM).
sku_name = "premium"

# Keep the default key when upgrading an existing vault; moving/removing it can
# replace/delete an endpoint. All target subnets/RGs/zones must already exist.
private_endpoints = {
  default = {
    subnet_id                     = "/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/network/providers/Microsoft.Network/virtualNetworks/orders-prod/subnets/private-endpoints"
    private_dns_zone_id           = "/subscriptions/22222222-2222-2222-2222-222222222222/resourceGroups/dns/providers/Microsoft.Network/privateDnsZones/privatelink.vaultcore.azure.net"
    custom_network_interface_name = "orders-prod-vault-primary-nic"
    private_ip_address            = "10.200.1.6" # Must be free and inside the actual subnet.
    manual_connection             = false
  }
  recovery = {
    subnet_id           = "/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/network-recovery/providers/Microsoft.Network/virtualNetworks/orders-recovery/subnets/private-endpoints"
    private_dns_zone_id = "/subscriptions/22222222-2222-2222-2222-222222222222/resourceGroups/dns/providers/Microsoft.Network/privateDnsZones/privatelink.vaultcore.azure.net"
    resource_group_name = "orders-eus2-prod-security-rg"
    location            = "eastus2"
    name                = "orders-prod-vault-recovery-pe"
    manual_connection   = true
    request_message     = "REPLACE_APPROVED_NETWORK_CHANGE: recovery application access"
  }
}

secret_officer_group_ids = { application_operations = "55555555-5555-5555-5555-555555555555" }
data_access = {
  cmk_consumer = {
    principal_id         = "44444444-4444-4444-4444-444444444444"
    principal_type       = "ServicePrincipal"
    role_definition_name = "Key Vault Crypto Service Encryption User"
  }
  crypto_operators = {
    principal_id         = "66666666-6666-6666-6666-666666666666"
    principal_type       = "Group"
    role_definition_name = "Key Vault Crypto Officer"
  }
}

# Optional DATA-PLANE provisioning: the runner must already have key-management
# permissions and private DNS/reachability. A new role assignment is not an
# immediate propagation guarantee; use a separately approved bootstrap when needed.
keys = {
  application-cmk = {
    key_type        = "RSA-HSM"
    key_size        = 3072
    key_opts        = ["wrapKey", "unwrapKey"]
    expiration_date = "2027-10-22T00:00:00Z" # Set a valid future initial expiration.
    rotation_policy = {
      expire_after         = "P180D"
      notify_before_expiry = "P30D"
      automatic            = { time_after_creation = "P90D" }
    }
    tags = { purpose = "application-encryption" }
  }
}

# Reuse approved routes; this pattern never creates or modifies action groups.
monitoring = {
  enabled                = true
  action_group_ids       = ["/subscriptions/33333333-3333-3333-3333-333333333333/resourceGroups/monitoring/providers/Microsoft.Insights/actionGroups/application-oncall"]
  availability_threshold = 99.9
  latency_threshold_ms   = 1000
  saturation_threshold   = 80
  severity               = 1
  frequency              = "PT1M"
  window_size            = "PT5M"
}

diagnostics = {
  enabled                        = true
  name                           = "orders-vault-central-audit"
  log_analytics_destination_type = "Dedicated" # Coordinate SOC query/table migration.
  storage_account_id             = "/subscriptions/33333333-3333-3333-3333-333333333333/resourceGroups/archive/providers/Microsoft.Storage/storageAccounts/replaceauditarchive"
  eventhub_authorization_rule_id = "/subscriptions/33333333-3333-3333-3333-333333333333/resourceGroups/siem/providers/Microsoft.EventHub/namespaces/replace-siem/authorizationRules/diagnostic-send"
  eventhub_name                  = "key-vault-audit"
}
