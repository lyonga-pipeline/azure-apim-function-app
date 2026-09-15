# Compeer Directory Services Pattern

## Overview

**What this deploys:** the hub-hosted Windows domain controller VMs —
resource group, NICs, VMs, optional data disks, optional domain-join, and
backup registration. AD DS role installation and domain-controller promotion
are **not** Terraform-owned (resolved decision, see below).

| Resource / module | Purpose |
|---|---|
| `module.windows_vm` | The domain controller VM(s), keyed by stable names (not `dc01`/`dc02`) |
| `module.network_interface` | Per-controller NICs with static private IPs + per-controller DNS server settings |
| `module.domain_join` | Optional Terraform-owned domain join, for a controller VM that needs to join an existing domain before manual AD DS promotion |
| `module.management_locks` | Optional `CanNotDelete`/`ReadOnly` lock |
| `azurerm_backup_protected_vm` | Optional Recovery Services Vault backup registration |

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

- VNet, subnets, NSGs, and routing are owned by the connectivity workspace, not the DC stack.
- Public jumpbox/RDP access is not created here.
- Domain controller candidates are keyed by stable names instead of hard-coded `dc01`, `dc02`, `dc03` resource blocks.
- NIC DNS servers are supported per controller through `domain_controllers[*].dns_servers`.
- Accelerated networking defaults to `true` for the enterprise baseline, and can be disabled per controller only when an approved VM size does not support it.
