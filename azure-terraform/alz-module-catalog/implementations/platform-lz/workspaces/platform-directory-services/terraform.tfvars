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
  created_on  = "2026-01-01"
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

  domain_controllers = {
    # Replace subnet_key, private IPs, zone placement, image SKU, and sizing with
    # approved values from IPAM, AD, Windows, and architecture owners before
    # enabling this workspace. subnet_key must be "prod-extdc-subnet"
    # (compeer.ext) or "prod-intdc-subnet" (agstar.local) per the hub's current
    # subnet plan - "domain_controllers" (the old combined subnet) no longer
    # exists. dc01/dc02 are assumed compeer.ext/agstar.local respectively below
    # - confirm the actual domain assignment with the AD team; private IPs
    # (10.0.10.x) are untouched since that range was never tied to the hub's
    # own addressing in the first place and needs its own IPAM confirmation.
    #
    # DC VM `name` / `computer_name` are kept explicit here on purpose: they use
    # the established AD server convention (AZR-SRV-ADDS-0N), which the AD team
    # owns. The naming module's adapted default is platform-<region>-<env>-dc-0N;
    # drop the `name` lines below to switch to it once AD signs off (tracks A2).
    dc01 = {
      name                           = "AZR-SRV-ADDS-01"
      computer_name                  = "AZR-SRV-ADDS-01"
      nic_name                       = "nic-azr-srv-adds-01"
      subnet_key                     = "prod-extdc-subnet" # compeer.ext - confirm with AD team
      private_ip_address             = "10.0.10.10"
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
          name                 = "disk-azr-srv-adds-01-data"
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
      name                           = "AZR-SRV-ADDS-02"
      computer_name                  = "AZR-SRV-ADDS-02"
      nic_name                       = "nic-azr-srv-adds-02"
      subnet_key                     = "prod-intdc-subnet" # agstar.local - confirm with AD team
      private_ip_address             = "10.0.10.11"
      dns_servers                    = ["10.0.10.10"]
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
          name                 = "disk-azr-srv-adds-02-data"
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
