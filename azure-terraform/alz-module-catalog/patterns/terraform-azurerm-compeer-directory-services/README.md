# Compeer Directory Services Pattern

This pattern deploys Azure infrastructure for hub-hosted directory services: resource group, NICs with stable keys, Windows VMs, optional data disks, optional diagnostics, optional AD DS/DNS role installation, optional domain join, optional AD DS promotion, optional RBAC, optional locks, and no-resource operational contracts.

> **⚠ Deviation — temporary, pending AD-team confirmation.** `deploy-runbook.tf` §7.2 / §15
> say AD DS role install + promotion are **not** Terraform-owned (Ansible / PowerShell DSC),
> and domain-admin secrets never go through Terraform variables. This pattern currently
> **does** drive both via `azurerm_virtual_machine_extension` (`ad_ds_role_install`,
> `ad_ds_promotion`), and `var.ad_ds_promotion_passwords` **lands in state**. This is a
> temporary bridge so DCs can stand up end to end. Before production the AD team must
> either record this as an approved exception, or set the `*.enabled` flags to `false`
> and hand promotion to the approved config-management pipeline (VM / NIC / disk /
> diagnostics stay Terraform-owned regardless). `TODO(ad-team)`.

AD DS/DNS role installation and DC promotion are present as disabled-by-default extension hooks. AD Sites and Services, DNS forwarder configuration, GPOs, and authoritative AD recovery operations remain outside this pattern.

The sandbox ADDNS implementation proved the practical VM shape: static private IPs, per-NIC DNS server settings for additional controllers, Windows Server images, and a two-step process where the VM is built before AD promotion is attempted. This pattern keeps those useful parts and removes the lab-only parts:

- VNet, subnets, NSGs, and routing are owned by the connectivity workspace, not the DC stack.
- Public jumpbox/RDP access is not created here.
- Domain controller candidates are keyed by stable names instead of hard-coded `dc01`, `dc02`, `dc03` resource blocks.
- NIC DNS servers are supported per controller through `domain_controllers[*].dns_servers`.
- Accelerated networking defaults to `true` for the enterprise baseline, and can be disabled per controller only when an approved VM size does not support it.
- AD DS/DNS role installation and DC promotion are optional extension hooks, but should stay disabled unless the AD team explicitly approves Terraform ownership for those steps.
