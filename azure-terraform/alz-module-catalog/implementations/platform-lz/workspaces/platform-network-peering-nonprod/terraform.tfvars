# PHASE 2: one non-production state for the explicitly approved environments below.
# Documentation values only. Replace all IDs/CIDRs/workspaces/change/IPAM references.
# Both halves are always managed together; platform identity peerings remain legacy-owned.
# This root is UNAPPLIED and disabled. Never toggle false on a live state to pause it.
enabled                   = false
tenant_id                 = "cccccccc-cccc-cccc-cccc-cccccccccccc"
execution_subscription_id = "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa"
allow_local_cli_auth      = false
allowed_environments      = ["dev", "test", "uat", "sandbox"]
# sandbox is canonical for the current workload blueprint. Use sbx instead only
# with an approved producer publishing sbx exactly; never translate labels here.

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
  orders_dev = {
    attachment_kind          = "workload"
    environment              = "dev" # Real producer environment, NOT "nonprod".
    spoke_virtual_network_id = "/subscriptions/bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb/resourceGroups/orders-dev/providers/Microsoft.Network/virtualNetworks/workload-cus-dev-int-orders-vnet"
    address_space            = ["10.21.0.0/24"]
    producer                 = { organization = "Compeer-Financial-Services", workspace = "workload-orders-dev", contract_version = "2.0.0" }
    naming_context           = { region = "centralus", environment = "dev", domain = "internal-apps", appcode = "orders" }
    approval_reference       = "REPLACE_WITH_APPROVED_NONPRODUCTION_CHANGE"
    ipam_reference           = "REPLACE_WITH_DEV_IPAM_RESERVATION"
    gateway_transit          = false
    allow_forwarded_traffic  = true
    peering_names = {
      spoke_to_hub = "peer-workload-cus-dev-int-orders-vnet-to-hub"
      hub_to_spoke = "peer-hub-to-workload-cus-dev-int-orders-vnet"
    }
    # Match the producer exactly; remove a zone only if producer intent also omits it.
    private_dns_zone_ids = {
      key_vault    = "/subscriptions/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa/resourceGroups/dns/providers/Microsoft.Network/privateDnsZones/privatelink.vaultcore.azure.net"
      storage_blob = "/subscriptions/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa/resourceGroups/dns/providers/Microsoft.Network/privateDnsZones/privatelink.blob.core.windows.net"
    }
    private_dns_link_names = {
      key_vault    = "workload-cus-dev-int-orders-vnet-link"
      storage_blob = "workload-cus-dev-int-orders-vnet-link"
    }
    tags = { Environment = "dev", Application = "orders", Owner = "PlatformNetworking", CostCenter = "REPLACE" }
  }
  orders_test = {
    attachment_kind          = "workload"
    environment              = "test" # Real producer environment, NOT "nonprod".
    spoke_virtual_network_id = "/subscriptions/bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb/resourceGroups/orders-test/providers/Microsoft.Network/virtualNetworks/workload-cus-test-int-orders-vnet"
    address_space            = ["10.22.0.0/24"]
    producer                 = { organization = "Compeer-Financial-Services", workspace = "workload-orders-test", contract_version = "2.0.0" }
    naming_context           = { region = "centralus", environment = "test", domain = "internal-apps", appcode = "orders" }
    approval_reference       = "REPLACE_WITH_APPROVED_NONPRODUCTION_CHANGE"
    ipam_reference           = "REPLACE_WITH_TEST_IPAM_RESERVATION"
    gateway_transit          = false
    allow_forwarded_traffic  = true
    peering_names = {
      spoke_to_hub = "peer-workload-cus-test-int-orders-vnet-to-hub"
      hub_to_spoke = "peer-hub-to-workload-cus-test-int-orders-vnet"
    }
    # Match the producer exactly; remove a zone only if producer intent also omits it.
    private_dns_zone_ids = {
      key_vault    = "/subscriptions/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa/resourceGroups/dns/providers/Microsoft.Network/privateDnsZones/privatelink.vaultcore.azure.net"
      storage_blob = "/subscriptions/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa/resourceGroups/dns/providers/Microsoft.Network/privateDnsZones/privatelink.blob.core.windows.net"
    }
    private_dns_link_names = {
      key_vault    = "workload-cus-test-int-orders-vnet-link"
      storage_blob = "workload-cus-test-int-orders-vnet-link"
    }
    tags = { Environment = "test", Application = "orders", Owner = "PlatformNetworking", CostCenter = "REPLACE" }
  }
  orders_uat = {
    attachment_kind          = "workload"
    environment              = "uat" # Real producer environment, NOT "nonprod".
    spoke_virtual_network_id = "/subscriptions/bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb/resourceGroups/orders-uat/providers/Microsoft.Network/virtualNetworks/workload-cus-uat-int-orders-vnet"
    address_space            = ["10.23.0.0/24"]
    producer                 = { organization = "Compeer-Financial-Services", workspace = "workload-orders-uat", contract_version = "2.0.0" }
    naming_context           = { region = "centralus", environment = "uat", domain = "internal-apps", appcode = "orders" }
    approval_reference       = "REPLACE_WITH_APPROVED_NONPRODUCTION_CHANGE"
    ipam_reference           = "REPLACE_WITH_UAT_IPAM_RESERVATION"
    gateway_transit          = false
    allow_forwarded_traffic  = true
    peering_names = {
      spoke_to_hub = "peer-workload-cus-uat-int-orders-vnet-to-hub"
      hub_to_spoke = "peer-hub-to-workload-cus-uat-int-orders-vnet"
    }
    # Match the producer exactly; remove a zone only if producer intent also omits it.
    private_dns_zone_ids = {
      key_vault    = "/subscriptions/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa/resourceGroups/dns/providers/Microsoft.Network/privateDnsZones/privatelink.vaultcore.azure.net"
      storage_blob = "/subscriptions/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa/resourceGroups/dns/providers/Microsoft.Network/privateDnsZones/privatelink.blob.core.windows.net"
    }
    private_dns_link_names = {
      key_vault    = "workload-cus-uat-int-orders-vnet-link"
      storage_blob = "workload-cus-uat-int-orders-vnet-link"
    }
    tags = { Environment = "uat", Application = "orders", Owner = "PlatformNetworking", CostCenter = "REPLACE" }
  }
  orders_sandbox = {
    attachment_kind          = "workload"
    environment              = "sandbox" # Real producer environment, NOT "nonprod".
    spoke_virtual_network_id = "/subscriptions/bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb/resourceGroups/orders-sandbox/providers/Microsoft.Network/virtualNetworks/workload-cus-sandbox-int-orders-vnet"
    address_space            = ["10.24.0.0/24"]
    producer                 = { organization = "Compeer-Financial-Services", workspace = "workload-orders-sandbox", contract_version = "2.0.0" }
    naming_context           = { region = "centralus", environment = "sandbox", domain = "internal-apps", appcode = "orders" }
    approval_reference       = "REPLACE_WITH_APPROVED_NONPRODUCTION_CHANGE"
    ipam_reference           = "REPLACE_WITH_SANDBOX_IPAM_RESERVATION"
    gateway_transit          = false
    allow_forwarded_traffic  = true
    peering_names = {
      spoke_to_hub = "peer-workload-cus-sandbox-int-orders-vnet-to-hub"
      hub_to_spoke = "peer-hub-to-workload-cus-sandbox-int-orders-vnet"
    }
    # Match the producer exactly; remove a zone only if producer intent also omits it.
    private_dns_zone_ids = {
      key_vault    = "/subscriptions/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa/resourceGroups/dns/providers/Microsoft.Network/privateDnsZones/privatelink.vaultcore.azure.net"
      storage_blob = "/subscriptions/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa/resourceGroups/dns/providers/Microsoft.Network/privateDnsZones/privatelink.blob.core.windows.net"
    }
    private_dns_link_names = {
      key_vault    = "workload-cus-sandbox-int-orders-vnet-link"
      storage_blob = "workload-cus-sandbox-int-orders-vnet-link"
    }
    tags = { Environment = "sandbox", Application = "orders", Owner = "PlatformNetworking", CostCenter = "REPLACE" }
  }
}
