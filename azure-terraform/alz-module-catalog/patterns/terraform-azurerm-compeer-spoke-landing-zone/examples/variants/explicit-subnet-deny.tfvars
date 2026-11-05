# SYNTHETIC REFERENCE ONLY: baseline.tfvars + this variant; replaces the entire spoke object.
# Explicit team-owned policy, not a blueprint default. Replace all example allocations and metadata.
environment = "prod"
spoke = {
  location                    = "centralus"
  appcode                     = "orders"
  domain                      = "internal-apps"
  address_space               = ["10.200.0.0/20"]
  reserved_address_spaces     = ["10.201.0.0/20", "10.40.0.0/16"]
  inspection_address_prefixes = ["10.40.0.0/16"]
  egress_next_hop_ip          = "10.102.0.4"
  private_endpoint_subnet_key = "private_endpoints"
  workload_access_group_ids   = {}
  workload_tags = {
    application         = "orders"
    owner               = "Application Operations"
    source_repo         = "ado://example/workloads/orders"
    created_on          = "2026-11-05"
    criticality_tier    = "tier-2"
    data_classification = "confidential"
    lifecycle_state     = "active"
    cost_center         = "CC-0000"
    gl_category         = "cloud-infrastructure"
    dr_tier             = "silver"
  }
  subnets = {
    application = {
      address_prefixes = ["10.200.0.0/24"]
      rules = {
        internal-https = {
          protocol = "Tcp", destination_port_range = "443", source_address_prefix = "10.40.10.0/24", destination_address_prefix = "10.200.0.0/24",
          access   = "Allow", priority = 300, direction = "Inbound"
        }
        approved-dns-udp = {
          protocol = "Udp", destination_port_range = "53", source_address_prefix = "10.200.0.0/24", destination_address_prefixes = ["10.102.0.10", "10.102.0.11"],
          access   = "Allow", priority = 300, direction = "Outbound"
        }
        approved-dns-tcp = {
          protocol = "Tcp", destination_port_range = "53", source_address_prefix = "10.200.0.0/24", destination_address_prefixes = ["10.102.0.10", "10.102.0.11"],
          access   = "Allow", priority = 310, direction = "Outbound"
        }
        approved-private-https = {
          protocol = "Tcp", destination_port_range = "443", source_address_prefix = "10.200.0.0/24", destination_address_prefix = "10.200.1.0/27",
          access   = "Allow", priority = 320, direction = "Outbound"
        }
        # Old names may be kept to avoid unnecessary rule renaming during adoption.
        baseline-deny-inbound = {
          protocol = "*", destination_port_range = "*", source_address_prefix = "*", destination_address_prefix = "*",
          access   = "Deny", priority = 4096, direction = "Inbound"
        }
        baseline-deny-outbound = {
          protocol = "*", destination_port_range = "*", source_address_prefix = "*", destination_address_prefix = "*",
          access   = "Deny", priority = 4096, direction = "Outbound"
        }
      }
      routes = {}
    }
    private_endpoints = {
      address_prefixes = ["10.200.1.0/27"]
      rules = {
        approved-private-https = {
          protocol = "Tcp", destination_port_range = "443", source_address_prefixes = ["10.200.0.0/24", "10.40.10.0/24"], destination_address_prefix = "10.200.1.0/27",
          access   = "Allow", priority = 300, direction = "Inbound"
        }
        baseline-deny-inbound = {
          protocol = "*", destination_port_range = "*", source_address_prefix = "*", destination_address_prefix = "*",
          access   = "Deny", priority = 4096, direction = "Inbound"
        }
        baseline-deny-outbound = {
          protocol = "*", destination_port_range = "*", source_address_prefix = "*", destination_address_prefix = "*",
          access   = "Deny", priority = 4096, direction = "Outbound"
        }
      }
      routes = {}
    }
  }
}
key_vault        = { enabled = true, sku_name = "standard", secret_readers = {}, secret_officer_group_ids = {} }
diagnostics      = { enabled = true, existing_settings = {} }
storage_accounts = {}
monitoring       = { enabled = false, alerts_enabled = false }
operations       = { create_action_group = false, notification_emails = [], action_group_ids = [], platform_action_group_keys = [] }
backup           = null
