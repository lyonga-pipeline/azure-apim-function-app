# PHASE 2: production attachment inventory. Documentation values, NOT approved Compeer IDs.
# This UNAPPLIED root is disabled. Replace every placeholder, approve IPAM/ownership,
# publish/pin the pattern and configure OIDC/RBAC/the shared-hub gate before enabling.
# Never use enabled=false to pause an applied state: that plans attachment deletion.
enabled                   = false
tenant_id                 = "cccccccc-cccc-cccc-cccc-cccccccccccc"
execution_subscription_id = "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa"
allow_local_cli_auth      = false # HCP injects credential FILE PATHS; no tokens/passwords here.

hub = {
  virtual_network_id = "/subscriptions/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa/resourceGroups/hub/providers/Microsoft.Network/virtualNetworks/shared-hub-vnet"
  address_space      = ["10.0.0.0/16"]
  organization       = "Compeer-Financial-Services"
  workspace          = "platform-connectivity"
  contract_version   = "0.1.0"
  gateway_ready      = false
}

# Replace with COMPLETE on-prem/partner/other-boundary IPAM ranges. Exclude this batch/hub.
reserved_address_spaces = ["172.16.0.0/12", "10.169.0.0/16", "10.21.0.0/24", "10.22.0.0/24", "10.23.0.0/24", "10.24.0.0/24"]
deployment_controls = {
  approval_reference           = "REPLACE_WITH_APPROVED_PRODUCTION_CHANGE"
  exclusive_ownership_verified = false
  shared_hub_gate_configured   = false
}

# Each entry ALWAYS creates both peering directions. Names are explicit to follow
# peer-<vnet>-to-hub / peer-hub-to-<vnet>; existing names must be preserved on import.
attachments = {
  orders_prod = {
    attachment_kind          = "workload"
    environment              = "prod"
    spoke_virtual_network_id = "/subscriptions/bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb/resourceGroups/orders-prod/providers/Microsoft.Network/virtualNetworks/workload-cus-prod-int-orders-vnet"
    address_space            = ["10.20.0.0/24"]
    producer                 = { organization = "Compeer-Financial-Services", workspace = "workload-orders-prod", contract_version = "2.0.0" }
    naming_context           = { region = "centralus", environment = "prod", domain = "internal-apps", appcode = "orders" }
    approval_reference       = "REPLACE_WITH_APPROVED_PRODUCTION_CHANGE"
    ipam_reference           = "REPLACE_WITH_PRODUCTION_IPAM_RESERVATION"
    gateway_transit          = false # Not needed simply for Palo Alto forwarding.
    allow_forwarded_traffic  = true  # Must match the approved NVA/UDR/return-path design.
    peering_names = {
      spoke_to_hub = "peer-workload-cus-prod-int-orders-vnet-to-hub"
      hub_to_spoke = "peer-hub-to-workload-cus-prod-int-orders-vnet"
    }
    # Must EXACTLY match producer DNS intent; {} only when the producer requests none.
    private_dns_zone_ids = {
      key_vault    = "/subscriptions/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa/resourceGroups/dns/providers/Microsoft.Network/privateDnsZones/privatelink.vaultcore.azure.net"
      storage_blob = "/subscriptions/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa/resourceGroups/dns/providers/Microsoft.Network/privateDnsZones/privatelink.blob.core.windows.net"
    }
    private_dns_link_names = {
      key_vault    = "workload-cus-prod-int-orders-vnet-link"
      storage_blob = "workload-cus-prod-int-orders-vnet-link"
    }
    tags = { Environment = "prod", Application = "orders", Owner = "PlatformNetworking", CostCenter = "REPLACE" }
  }
}
