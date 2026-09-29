# Compeer Directory Services Pattern

## Overview

**What this deploys:** the Windows domain controller VMs, plus - as of the
23 Sep 2026 placement decision - their own dedicated identity VNet, peered
to the hub. This reverses the earlier hub-hosted DC placement: domain
controllers now live in an isolated identity VNet/subscription rather than
directly in a hub subnet, per the Azure Landing Zone Architecture & Design
Document (v13) and the resource-placement sheet. `identity_vnet = null`
keeps the legacy shape (a caller-supplied subnet on an externally-owned VNet,
e.g. the hub) for anyone not yet migrated. AD DS role installation and
domain-controller promotion are **not** Terraform-owned (resolved decision,
see below).

| Resource / module | Purpose |
|---|---|
| `module.identity_vnet` | The dedicated identity VNet + subnets (optional - `identity_vnet = null` skips it) |
| `module.identity_vnet_to_hub_peering` | Spoke->hub half of the peering (optional - needs both `identity_vnet` and `hub_connection`) |
| `module.network_security_groups` / `module.route_tables` | NSGs/route tables for the identity VNet's subnets, associated via inline `subnet.nsg_key` / `subnet.route_table_key` hints |
| `module.recovery_services_vaults` | Optional Recovery Services vault(s) this pattern creates and owns directly (e.g. the dedicated identity-subscription DC backup vault) |
| `module.windows_vm` | The domain controller VM(s), keyed by stable names (not `dc01`/`dc02`) |
| `module.network_interface` | Per-controller NICs with static private IPs + per-controller DNS server settings. `subnet_id` (explicit) wins over `subnet_key` (resolved against `identity_vnet`) |
| `module.domain_join` | Optional Terraform-owned domain join, for a controller VM that needs to join an existing domain before manual AD DS promotion |
| `module.management_locks` | Optional `CanNotDelete`/`ReadOnly` lock |
| `azurerm_backup_protected_vm` | Optional Recovery Services Vault backup registration - defaults to this pattern's own `recovery_services_vaults["identity"]` when `dc_backup.vault_name` isn't set explicitly |

**`terraform_data.controller_contract` — what it enforces:** every domain
controller needs its sensitive local admin password actually supplied
(`admin_passwords`), and every enabled domain-join needs its sensitive join
password (`domain_join_passwords`) — the contract fails the plan with a
clear message instead of the underlying module failing at apply time. See
`tests/controller_contract.tftest.hcl`.

---

This pattern deploys Azure infrastructure for hub-hosted directory services: resource group, NICs with stable keys, Windows VMs, optional data disks, optional diagnostics, optional domain join, optional RBAC, optional locks, and no-resource operational contracts.

**AD DS role installation and domain-controller promotion are not
Terraform-owned.** `deploy-runbook.tf` §7.2 / §15 always specified this
(Ansible / PowerShell DSC instead, domain-admin secrets never through
Terraform variables). This pattern briefly carried a Terraform-owned bridge
for both (`azurerm_virtual_machine_extension.ad_ds_role_install` /
`.ad_ds_promotion` + `var.ad_ds_promotion_passwords`) to stand DCs up
end-to-end during early build-out. **Confirmed with the network/AD team:**
Terraform stops at a domain-joined, ready-to-promote VM; AD DS role
installation and promotion happen manually (or via the approved Ansible/DSC
pipeline) once the VM has joined the domain. The bridge has been removed —
VM / NIC / disk / diagnostics / lock / domain-join resources remain
Terraform-owned. AD Sites and Services, DNS forwarder configuration, GPOs,
and authoritative AD recovery operations also remain outside this pattern.

The sandbox ADDNS implementation proved the practical VM shape: static private IPs, per-NIC DNS server settings for additional controllers, Windows Server images, and a two-step process where the VM is built before AD promotion is attempted. This pattern keeps those useful parts and removes the lab-only parts:

- VNet, subnets, NSGs, and routing for the domain controllers are owned by
  this pattern itself (`identity_vnet`), peered to the hub via
  `hub_connection` - not borrowed from the connectivity workspace's hub VNet,
  per the 23 Sep 2026 placement decision. `identity_vnet = null` keeps the
  legacy shape (an externally-owned subnet, e.g. still on the hub) for a
  caller not yet migrated.
- Public jumpbox/RDP access is not created here.
- Domain controller candidates are keyed by stable names instead of hard-coded `dc01`, `dc02`, `dc03` resource blocks.
- NIC DNS servers are supported per controller through `domain_controllers[*].dns_servers`.
- Accelerated networking defaults to `true` for the enterprise baseline, and can be disabled per controller only when an approved VM size does not support it.

## Two Domain Families

The naming module produces two independent VM-name families for this
pattern's domain controllers, per Appendix F (Table 28) of the design doc:
`platform-<region>-<env>-dc-0<n>` for the primary ("compeer forest") domain,
and `platform-<region>-<env>-extdc-0<n>` for the compeer.ext forest. Each
family numbers its own instances independently. The consuming workspace's
`naming.tf` selects between them by convention (a domain-controller key
starting with `ext` uses the `extdc` family); this pattern itself only
receives the already-resolved `name` on each `domain_controllers` entry, the
same as always.
