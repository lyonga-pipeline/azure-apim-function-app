# Deployable tfvars for this workspace.
#
# Auth is NOT set here:
#   tenant_id       -> shared HCP variable set (Terraform category, key: tenant_id)
#   subscription_id -> this workspace's Terraform-category variable in HCP
# The azurerm provider reads both from those Terraform variables.
#

location                    = "centralus"
tfe_organization            = "Compeer-Financial-Services"
connectivity_workspace_name = "platform-connectivity"

tags = {
  managed_by          = "terraform"
  terraform_workspace = "platform-palo-alto"
}

# Terraform-native VM-Series deployment (no Marketplace solution template,
# no vendorized/AVM firewall module - approved: custom build, PAYG licensing).
# 2 firewalls, mgmt/untrust/trust NICs + Sunstream dataplane NICs, a trust ILB
# and a Sunstream ILB, storage bootstrap. subnet_key values resolve against the
# connectivity workspace's subnet_ids output.
#
# subnet_key values and private IPs below were realigned to connectivity's
# current hub plan (10.102.0.0/16 - Dan's Teams post, 2026-09-17): the old
# "fw-mgmt"/"fw-untrust"/"fw-trust"/"fw-sunstream" keys never matched any real
# connectivity subnet (this pattern predates that reconciliation), so every
# subnet_id here was previously resolving to null. Private IPs were recomputed
# using this file's own existing convention (fw1 = subnet base + 4, fw2 = base
# + 5, ILB frontend = base + 10 - i.e. the first two/eleventh usable addresses
# after Azure's 4 reserved addresses per subnet) applied to the new subnet
# bases. Not confirmed by the network/Palo Alto team - verify before go-live.
#
# Image/license: paloaltonetworks/vmseries-flex, plan "bundle2" - Azure
# Marketplace PAYG (pay-as-you-go, hourly), NOT BYOL. bundle2 is the fuller
# PAYG bundle (NGFW + Threat Prevention + DNS Security + WildFire + URL
# Filtering/PAN-DB + GlobalProtect + Premium Support) vs bundle1 (NGFW +
# Threat Prevention + Premium Support only). Verify current entitlements
# against the live Azure Marketplace listing before go-live - bundle
# contents are Palo Alto's to change. This is also the pattern's own
# variables.tf default for source_image_reference/plan, so it's implicit
# below; listed here for visibility.
palo_alto = {
  enabled = true

  # Accept the VM-Series image agreement once per subscription (NOT the template).
  marketplace_agreement = {
    enabled   = true
    publisher = "paloaltonetworks"
    offer     = "vmseries-flex"
    plan      = "bundle2"
  }

  # Bootstrap storage. The firewall reads the file share over SMB from its mgmt
  # NIC. Keep it PRIVATE with a service endpoint from the Palo mgmt subnet -
  # NOT a public endpoint. `publicNetworkAccess` stays "Enabled" only because
  # service endpoints require it; the account is firewalled to that one subnet.
  bootstrap_storage_account = {
    name                          = "stpanbootstrapprod01"
    account_replication_type      = "ZRS"
    shared_access_key_enabled     = true # bootstrap needs the account key
    public_network_access_enabled = true # required for a service endpoint; Deny + allow-list below
    network_rules = {
      default_action      = "Deny"
      bypass              = ["AzureServices"]
      allowed_subnet_keys = ["prod-mgmt-subnet"] # resolved from the connectivity output
      # allowed_ip_ranges = []                        # on-prem CIDR only if genuinely needed
    }
    file_shares = {
      bootstrap = { quota = 5 }
    }
  }

  # Bootstrap Key Vault for cert authentication / Panorama secrets. PRIVATE by
  # default (private endpoint + Deny). The firewall MIs are granted
  # "Key Vault Certificates User" + "Secrets User" automatically.
  bootstrap_key_vault = {
    name    = "kv-pan-bootstrap-prod"
    network = { mode = "private" }
    private_endpoint = {
      name       = "pep-kv-pan-bootstrap"
      subnet_key = "private_endpoints"
      # private_dns_zone_ids = [<privatelink.vaultcore.azure.net zone id>]
    }
  }

  bootstrap_share_layout = {
    bootstrap = {
      directories = ["config", "content", "license", "software"]
      files = {
        "init-cfg.txt" = {
          path = "config"
          # PAN-OS 10+ pulls the rest from Panorama / Strata Cloud Manager.
          content = <<-CFG
            type=dhcp-client
            hostname=$${hostname}
            panorama-server=10.10.0.10
            tplname=Compeer-Hub
            dgname=Compeer-Hub-FW
            dhcp-send-hostname=yes
            dhcp-send-client-id=yes
            dhcp-accept-server-hostname=yes
            dhcp-accept-server-domain=yes
          CFG
        }
      }
    }
  }

  public_ips = {
    fw_mgmt    = { name = "pip-fw-mgmt", allocation_method = "Static", sku = "Standard" }
    fw_untrust = { name = "pip-fw-untrust", allocation_method = "Static", sku = "Standard" }
  }

  network_interfaces = {
    fw1_mgmt      = { name = "nic-fw1-mgmt", ip_configurations = { primary = { name = "ipc", subnet_key = "prod-mgmt-subnet", primary = true, private_ip_address_allocation = "Dynamic", public_ip_key = "fw_mgmt" } } }
    fw1_untrust   = { name = "nic-fw1-untrust", ip_forwarding_enabled = true, ip_configurations = { primary = { name = "ipc", subnet_key = "prod-fw-untrust-subnet", primary = true, private_ip_address_allocation = "Static", private_ip_address = "10.102.4.68", public_ip_key = "fw_untrust" } } }
    fw1_trust     = { name = "nic-fw1-trust", ip_forwarding_enabled = true, ip_configurations = { primary = { name = "ipc", subnet_key = "prod-fw-trust-subnet", primary = true, private_ip_address_allocation = "Static", private_ip_address = "10.102.4.36" } } }
    fw1_sunstream = { name = "nic-fw1-sunstream", ip_forwarding_enabled = true, ip_configurations = { primary = { name = "ipc", subnet_key = "prod-fw-partner-subnet", primary = true, private_ip_address_allocation = "Static", private_ip_address = "10.102.4.100" } } }
    fw2_mgmt      = { name = "nic-fw2-mgmt", ip_configurations = { primary = { name = "ipc", subnet_key = "prod-mgmt-subnet", primary = true, private_ip_address_allocation = "Dynamic" } } }
    fw2_untrust   = { name = "nic-fw2-untrust", ip_forwarding_enabled = true, ip_configurations = { primary = { name = "ipc", subnet_key = "prod-fw-untrust-subnet", primary = true, private_ip_address_allocation = "Static", private_ip_address = "10.102.4.69" } } }
    fw2_trust     = { name = "nic-fw2-trust", ip_forwarding_enabled = true, ip_configurations = { primary = { name = "ipc", subnet_key = "prod-fw-trust-subnet", primary = true, private_ip_address_allocation = "Static", private_ip_address = "10.102.4.37" } } }
    fw2_sunstream = { name = "nic-fw2-sunstream", ip_forwarding_enabled = true, ip_configurations = { primary = { name = "ipc", subnet_key = "prod-fw-partner-subnet", primary = true, private_ip_address_allocation = "Static", private_ip_address = "10.102.4.101" } } }
  }

  load_balancers = {
    trust = {
      name = "lb-fw-trust"
      sku  = "Standard"
      frontend_ip_configurations = {
        trust = { name = "fe-trust", subnet_key = "prod-fw-trust-subnet", private_ip_address_allocation = "Static", private_ip_address = "10.102.4.42" }
      }
      backend_address_pools = { fw = {} }
      probes                = { https = { port = 443, protocol = "Tcp" } }
      rules = {
        all = { frontend_ip_configuration_name = "trust", backend_address_pool_names = ["fw"], probe_name = "https", protocol = "All", frontend_port = 0, backend_port = 0, floating_ip_enabled = true }
      }
    }
    sunstream = {
      name = "lb-fw-sunstream"
      sku  = "Standard"
      frontend_ip_configurations = {
        sunstream = { name = "fe-sunstream", subnet_key = "prod-fw-partner-subnet", private_ip_address_allocation = "Static", private_ip_address = "10.102.4.106" }
      }
      backend_address_pools = { fw = {} }
      probes                = { https = { port = 443, protocol = "Tcp" } }
      rules = {
        all = { frontend_ip_configuration_name = "sunstream", backend_address_pool_names = ["fw"], probe_name = "https", protocol = "All", frontend_port = 0, backend_port = 0, floating_ip_enabled = true }
      }
    }
  }

  # BLOCKER before the first real apply: both admin_ssh_keys entries below are
  # still the literal placeholder "ssh-ed25519 AAAA... replace" - this is not
  # a usable key and was never a real one. Swap in the real public key(s) the
  # network team will use to manage these firewalls before running this
  # workspace for real.
  virtual_machines = {
    fw1 = {
      name                   = "vm-fw-hub-01"
      size                   = "Standard_D3_v2"
      zone                   = "1"
      admin_username         = "panadmin"
      network_interface_keys = ["fw1_mgmt", "fw1_untrust", "fw1_trust", "fw1_sunstream"]
      admin_ssh_keys         = [{ username = "panadmin", public_key = "ssh-ed25519 AAAA... replace" }]
      # azure-file-share against the pattern's own bootstrap_storage_account:
      # omit storage_account_name/key and the pattern reads the key itself.
      bootstrap = {
        mode = "azure-file-share"
      }
    }
    fw2 = {
      name                   = "vm-fw-hub-02"
      size                   = "Standard_D3_v2"
      zone                   = "2"
      admin_username         = "panadmin"
      network_interface_keys = ["fw2_mgmt", "fw2_untrust", "fw2_trust", "fw2_sunstream"]
      admin_ssh_keys         = [{ username = "panadmin", public_key = "ssh-ed25519 AAAA... replace" }]
      bootstrap = {
        mode             = "custom-data"
        init_cfg_content = "type=dhcp-client\nhostname=vm-fw-hub-02\npanorama-server=10.10.0.10\ntplname=Compeer-Hub\ndgname=Compeer-Hub-FW\n"
      }
    }
  }

}

# Only needed when a firewall's bootstrap points at an EXTERNAL storage account
# (e.g. a separate phase-1 bootstrap workspace). Omit to use the pattern's own
# bootstrap_storage_account. Keyed by the palo_alto.virtual_machines key.
palo_alto_bootstrap_storage_keys = {
  # fw1 = "<phase-1 bootstrap storage primary access key>"
}
