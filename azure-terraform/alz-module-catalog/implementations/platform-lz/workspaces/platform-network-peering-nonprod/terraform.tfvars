# PHASE 2: one non-production state for the explicitly approved environments below.
# Documentation values only. Replace all IDs/CIDRs/workspaces/change/IPAM references.
# Both halves are always managed together; platform identity peerings remain legacy-owned.
# This root is UNAPPLIED and disabled. Never toggle false on a live state to pause it.
enabled                   = false
tenant_id                 = "cccccccc-cccc-cccc-cccc-cccccccccccc"
execution_subscription_id = "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa"
allow_local_cli_auth      = false
allowed_environments      = ["np1", "np2", "np3"] # Add dev/test/uat/perf only through network approval.

hub = {
  virtual_network_id = "/subscriptions/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa/resourceGroups/hub/providers/Microsoft.Network/virtualNetworks/shared-hub-vnet"
  address_space      = ["10.0.0.0/16"]
  organization       = "Compeer-Financial-Services"
  workspace          = "platform-connectivity"
  contract_version   = "0.1.0"
  gateway_ready      = false
}

# Replace with complete external IPAM; include prod, exclude THIS batch and the hub.
reserved_address_spaces = ["172.16.0.0/12", "10.169.0.0/16", "10.20.0.0/24"]
deployment_controls = {
  approval_reference           = "REPLACE_WITH_APPROVED_NONPRODUCTION_CHANGE"
  exclusive_ownership_verified = false
  shared_hub_gate_configured   = false
}

# One entry per VNet that actually EXISTS. No automatic environment matrix.
# HCP injects credential file paths; enable only after OIDC/RBAC and gate setup.
attachments = {
  orders_np1 = {
    attachment_kind          = "workload"
    environment              = "np1" # Real producer environment, NOT "nonprod".
    spoke_virtual_network_id = "/subscriptions/bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb/resourceGroups/orders-np1/providers/Microsoft.Network/virtualNetworks/workload-cus-np1-int-orders-vnet"
    address_space            = ["10.21.0.0/24"]
    producer                 = { organization = "Compeer-Financial-Services", workspace = "workload-orders-np1", contract_version = "2.0.0" }
    naming_context           = { region = "centralus", environment = "np1", domain = "internal-apps", appcode = "orders" }
    approval_reference       = "REPLACE_WITH_APPROVED_NONPRODUCTION_CHANGE"
    ipam_reference           = "REPLACE_WITH_NP1_IPAM_RESERVATION"
    gateway_transit          = false
    allow_forwarded_traffic  = true
    peering_names = {
      spoke_to_hub = "peer-workload-cus-np1-int-orders-vnet-to-hub"
      hub_to_spoke = "peer-hub-to-workload-cus-np1-int-orders-vnet"
    }
    # Match the producer exactly; remove a zone only if producer intent also omits it.
    private_dns_zone_ids = {
      key_vault    = "/subscriptions/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa/resourceGroups/dns/providers/Microsoft.Network/privateDnsZones/privatelink.vaultcore.azure.net"
      storage_blob = "/subscriptions/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa/resourceGroups/dns/providers/Microsoft.Network/privateDnsZones/privatelink.blob.core.windows.net"
    }
    private_dns_link_names = {
      key_vault    = "workload-cus-np1-int-orders-vnet-link"
      storage_blob = "workload-cus-np1-int-orders-vnet-link"
    }
    tags = { Environment = "np1", Application = "orders", Owner = "PlatformNetworking", CostCenter = "REPLACE" }
  }
  orders_np2 = {
    attachment_kind          = "workload"
    environment              = "np2" # Real producer environment, NOT "nonprod".
    spoke_virtual_network_id = "/subscriptions/bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb/resourceGroups/orders-np2/providers/Microsoft.Network/virtualNetworks/workload-cus-np2-int-orders-vnet"
    address_space            = ["10.22.0.0/24"]
    producer                 = { organization = "Compeer-Financial-Services", workspace = "workload-orders-np2", contract_version = "2.0.0" }
    naming_context           = { region = "centralus", environment = "np2", domain = "internal-apps", appcode = "orders" }
    approval_reference       = "REPLACE_WITH_APPROVED_NONPRODUCTION_CHANGE"
    ipam_reference           = "REPLACE_WITH_NP2_IPAM_RESERVATION"
    gateway_transit          = false
    allow_forwarded_traffic  = true
    peering_names = {
      spoke_to_hub = "peer-workload-cus-np2-int-orders-vnet-to-hub"
      hub_to_spoke = "peer-hub-to-workload-cus-np2-int-orders-vnet"
    }
    # Match the producer exactly; remove a zone only if producer intent also omits it.
    private_dns_zone_ids = {
      key_vault    = "/subscriptions/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa/resourceGroups/dns/providers/Microsoft.Network/privateDnsZones/privatelink.vaultcore.azure.net"
      storage_blob = "/subscriptions/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa/resourceGroups/dns/providers/Microsoft.Network/privateDnsZones/privatelink.blob.core.windows.net"
    }
    private_dns_link_names = {
      key_vault    = "workload-cus-np2-int-orders-vnet-link"
      storage_blob = "workload-cus-np2-int-orders-vnet-link"
    }
    tags = { Environment = "np2", Application = "orders", Owner = "PlatformNetworking", CostCenter = "REPLACE" }
  }
  orders_np3 = {
    attachment_kind          = "workload"
    environment              = "np3" # Real producer environment, NOT "nonprod".
    spoke_virtual_network_id = "/subscriptions/bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb/resourceGroups/orders-np3/providers/Microsoft.Network/virtualNetworks/workload-cus-np3-int-orders-vnet"
    address_space            = ["10.23.0.0/24"]
    producer                 = { organization = "Compeer-Financial-Services", workspace = "workload-orders-np3", contract_version = "2.0.0" }
    naming_context           = { region = "centralus", environment = "np3", domain = "internal-apps", appcode = "orders" }
    approval_reference       = "REPLACE_WITH_APPROVED_NONPRODUCTION_CHANGE"
    ipam_reference           = "REPLACE_WITH_NP3_IPAM_RESERVATION"
    gateway_transit          = false
    allow_forwarded_traffic  = true
    peering_names = {
      spoke_to_hub = "peer-workload-cus-np3-int-orders-vnet-to-hub"
      hub_to_spoke = "peer-hub-to-workload-cus-np3-int-orders-vnet"
    }
    # Match the producer exactly; remove a zone only if producer intent also omits it.
    private_dns_zone_ids = {
      key_vault    = "/subscriptions/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa/resourceGroups/dns/providers/Microsoft.Network/privateDnsZones/privatelink.vaultcore.azure.net"
      storage_blob = "/subscriptions/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa/resourceGroups/dns/providers/Microsoft.Network/privateDnsZones/privatelink.blob.core.windows.net"
    }
    private_dns_link_names = {
      key_vault    = "workload-cus-np3-int-orders-vnet-link"
      storage_blob = "workload-cus-np3-int-orders-vnet-link"
    }
    tags = { Environment = "np3", Application = "orders", Owner = "PlatformNetworking", CostCenter = "REPLACE" }
  }
}
