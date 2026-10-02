# Deployable tfvars for this workspace.
#
# Auth is NOT set here:
#   tenant_id       -> shared HCP variable set (Terraform category, key: tenant_id)
#   subscription_id -> this workspace's Terraform-category variable in HCP
# The azurerm provider reads both from those Terraform variables.
#

location                    = "centralus"
environment                 = "prod"
tfe_organization            = "Compeer-Financial-Services"
management_workspace_name   = "platform-management"
connectivity_workspace_name = "platform-connectivity"

platform_tags = {
  application = "alz-platform-directory-services"
  # Same short code the naming module's abbr map uses for this component
  # (directory-services -> ds), so the tag matches the actual name prefix.
  appcode     = "ds"
  owner       = "Cloud Enablement"
  source_repo = "ado://Compeer/landing-zone"
  # created_on intentionally NOT set here - this workspace's root main.tf
  # owns it via a time_static resource (computed once on first apply,
  # stable across every later plan) and supersedes any value set here.
  # Platform tier-0: foundational enterprise/platform service (identity -
  # domain controllers) required for other systems.
  criticality_tier    = "tier-0"
  data_classification = "confidential"
  lifecycle_state     = "active"
  cost_center         = "CC-0000"
  gl_category         = "cloud-infrastructure"
  # optional / conditional - set where you have a value
  # application_component = "..."
  # modified_on           = "2026-01-01"
  # created_by intentionally omitted - defaults to "Terraform" now (accurate:
  # this workspace IS how the resource gets created), replacing the old
  # additional_tags workaround below.
  # dr_tier was "tier-0" here - that's a criticality_tier value, not one of
  # the doc's four dr_tier values (gold/silver/bronze/none), and would now
  # fail validation outright. Read as "silver" - this is my inference, not a
  # confirmed decision; get this confirmed with whoever owns the actual DR
  # posture (domain controllers are core identity infra, so "gold" may
  # actually be more appropriate - flagging rather than guessing further).
  dr_tier = "silver"
  # expiration_date      = "2026-12-31"   # sandbox / temporary / POC only
}

directory_services = {
  enabled = false

  resource_group = {}

  # 23 Sep 2026 placement decision: domain controllers move off the hub into
  # this dedicated identity VNet, peered to the hub (this reverses the
  # earlier hub-hosted DC decision - see platform-connectivity's tfvars,
  # which no longer carries prod-extdc-subnet/prod-intdc-subnet). Address
  # space is TENTATIVE - picked as the next /24 block after the hub's
  # 10.102.0.0/16 allocation, clearly non-overlapping, but NOT yet confirmed
  # against the real IPAM plan. Confirm with the network team before this
  # workspace is ever enabled.
  identity_vnet = {
    address_space = ["10.103.0.0/24"]
    subnets = {
      # compeer forest (dc01/dc02)
      dc-subnet = { address_prefixes = ["10.103.0.0/27"], route_table_key = "to_firewall", nsg_key = "domain_controllers" }
      # compeer.ext (extdc01/extdc02)
      extdc-subnet = { address_prefixes = ["10.103.0.32/27"], route_table_key = "to_firewall", nsg_key = "domain_controllers" }
    }
  }
  # hub_connection is NOT set here - this workspace's root main.tf derives it
  # automatically from platform-connectivity's published hub_virtual_network_id.

  network_security_groups = {
    # TODO: add real DC-specific rules (AD DS/Kerberos/LDAP/DNS ports, scoped
    # to the hub and spoke ranges that need domain services) once the AD/
    # network team defines them. Empty for now - Deny-by-default per the
    # baseline landing-zone posture until those rules are approved.
    domain_controllers = { rules = {} }
  }

  route_tables = {
    to_firewall = {
      bgp_route_propagation_enabled = false
      routes = {
        # Same firewall ILB IP as platform-connectivity's own to_firewall
        # route table (10.102.4.42) - default route through the shared Palo
        # Alto HA pair, reachable via the hub<->identity peering.
        default = { address_prefix = "0.0.0.0/0", next_hop_type = "VirtualAppliance", next_hop_in_ip_address = "10.102.4.42" }
      }
    }
  }

  recovery_services_vaults = {
    # platform-cus-prod-identity-rsv - dedicated backup vault for the 4 DCs,
    # kept in the identity subscription rather than shared with platform-
    # management's vault (23 Sep 2026 placement decision).
    identity = {
      sku               = "Standard"
      storage_mode_type = "GeoRedundant"
      backup_policy_vm = {
        domain_controllers = {
          name     = "bp-vm-domain-controllers-daily"
          timezone = "Central Standard Time"
          backup = {
            frequency = "Daily"
            time      = "23:00"
          }
          retention_daily = { count = 30 }
        }
      }
    }
  }

  domain_controllers = {
    # Replace private IPs, zone placement, image SKU, and sizing with approved
    # values from IPAM, AD, Windows, and architecture owners before enabling
    # this workspace. Private IPs (10.103.0.x) are TENTATIVE - see
    # identity_vnet's own address-space note above.
    #
    # Naming module default now applies (platform-<region>-<env>-dc-0N /
    # -extdc-0N) - the AD team's earlier AZR-SRV-ADDS-0N convention is no
    # longer used, per the confirmed Appendix F naming standard (tracks A2,
    # now resolved). computer_name (NetBIOS, <=15 chars) now also defaults
    # from the naming module (AZR-<region>-ADS/EXD-0N, e.g. AZR-CUS-ADS-01) -
    # not set explicitly per key below anymore. This is a stopgap pending the
    # Teams "New Landing Zone - Cloud Enablement" thread's actual final
    # answer (Dmitry has the authoritative doc); override with an explicit
    # `computer_name` here once that's confirmed, if it differs.
    dc01 = {
      nic_name                       = "nic-platform-cus-prod-dc-01"
      subnet_key                     = "dc-subnet" # compeer forest
      private_ip_address             = "10.103.0.4"
      vm_size                        = "Standard_D2s_v5"
      zone                           = "1"
      admin_username                 = "azureadmin"
      accelerated_networking_enabled = true
      source_image_reference = {
        publisher = "MicrosoftWindowsServer"
        offer     = "WindowsServer"
        sku       = "2022-datacenter-azure-edition"
        version   = "latest"
      }
      os_disk = {
        caching              = "ReadWrite"
        storage_account_type = "Premium_LRS"
      }
      data_disks = {
        ad_data = {
          name                 = "disk-platform-cus-prod-dc-01-data"
          lun                  = 0
          disk_size_gb         = 128
          storage_account_type = "Premium_LRS"
          caching              = "ReadOnly"
        }
      }
      diagnostics = {
        enabled = false
      }
    }
    dc02 = {
      nic_name                       = "nic-platform-cus-prod-dc-02"
      subnet_key                     = "dc-subnet" # compeer forest
      private_ip_address             = "10.103.0.5"
      dns_servers                    = ["10.103.0.4"] # dc01
      vm_size                        = "Standard_D2s_v5"
      zone                           = "2"
      admin_username                 = "azureadmin"
      accelerated_networking_enabled = true
      source_image_reference = {
        publisher = "MicrosoftWindowsServer"
        offer     = "WindowsServer"
        sku       = "2022-datacenter-azure-edition"
        version   = "latest"
      }
      os_disk = {
        caching              = "ReadWrite"
        storage_account_type = "Premium_LRS"
      }
      data_disks = {
        ad_data = {
          name                 = "disk-platform-cus-prod-dc-02-data"
          lun                  = 0
          disk_size_gb         = 128
          storage_account_type = "Premium_LRS"
          caching              = "ReadOnly"
        }
      }
      diagnostics = {
        enabled = false
      }
    }
    extdc01 = {
      nic_name                       = "nic-platform-cus-prod-extdc-01"
      subnet_key                     = "extdc-subnet" # compeer.ext
      private_ip_address             = "10.103.0.36"
      vm_size                        = "Standard_D2s_v5"
      zone                           = "1"
      admin_username                 = "azureadmin"
      accelerated_networking_enabled = true
      source_image_reference = {
        publisher = "MicrosoftWindowsServer"
        offer     = "WindowsServer"
        sku       = "2022-datacenter-azure-edition"
        version   = "latest"
      }
      os_disk = {
        caching              = "ReadWrite"
        storage_account_type = "Premium_LRS"
      }
      data_disks = {
        ad_data = {
          name                 = "disk-platform-cus-prod-extdc-01-data"
          lun                  = 0
          disk_size_gb         = 128
          storage_account_type = "Premium_LRS"
          caching              = "ReadOnly"
        }
      }
      diagnostics = {
        enabled = false
      }
    }
    extdc02 = {
      nic_name                       = "nic-platform-cus-prod-extdc-02"
      subnet_key                     = "extdc-subnet" # compeer.ext
      private_ip_address             = "10.103.0.37"
      dns_servers                    = ["10.103.0.36"] # extdc01
      vm_size                        = "Standard_D2s_v5"
      zone                           = "2"
      admin_username                 = "azureadmin"
      accelerated_networking_enabled = true
      source_image_reference = {
        publisher = "MicrosoftWindowsServer"
        offer     = "WindowsServer"
        sku       = "2022-datacenter-azure-edition"
        version   = "latest"
      }
      os_disk = {
        caching              = "ReadWrite"
        storage_account_type = "Premium_LRS"
      }
      data_disks = {
        ad_data = {
          name                 = "disk-platform-cus-prod-extdc-02-data"
          lun                  = 0
          disk_size_gb         = 128
          storage_account_type = "Premium_LRS"
          caching              = "ReadOnly"
        }
      }
      diagnostics = {
        enabled = false
      }
    }
  }

  # Enrolls all 4 DCs into recovery_services_vaults.identity (above) by
  # default - vault_name/vault_resource_group_name are left unset so the
  # pattern defaults them to that locally-created vault.
  dc_backup = {
    backup_policy_key = "domain_controllers"
    protected_controllers = {
      dc01    = {}
      dc02    = {}
      extdc01 = {}
      extdc02 = {}
    }
  }

  operational_contracts = {
    ad_promotion = {
      enabled              = false
      implementation_state = "manual-control"
      required_controls    = ["AD DS role installation", "AD team promotion runbook", "replication validation", "DNS forwarder validation"]
      notes                = "Confirmed with the network/AD team: AD DS role installation and domain-controller promotion are not Terraform-owned. Terraform stops at a domain-joined, ready-to-promote VM; the AD team installs AD DS/DNS roles and promotes/configures controllers manually (or via the approved Ansible/DSC pipeline) once the VM has joined the domain."
    }
  }
}

admin_passwords = {
  # Supply matching sensitive HCP Terraform variables before enabling:
  # dc01 = "<sensitive>"
  # dc02 = "<sensitive>"
}
domain_join_passwords = {}
