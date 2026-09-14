# Compeer Shared Services Pattern

## Overview

**What this deploys:** a thin wrapper — `module "shared_services" { source =
"../terraform-azurerm-compeer-workload-spoke" ... }` — around the
`workload-spoke` pattern, so the shared-services VNet gets the exact same
VNet/subnet/NSG/route-table/peering/Key Vault composition as any workload
spoke, but in its own platform-owned workspace rather than a workload one.
Because it's a pure wrapper, any fix made to `workload-spoke` (e.g. its
`network_acls` handling — see that pattern's README) is inherited here
automatically; see `tests/defaults.tftest.hcl`, which exists specifically to
confirm that inheritance.

---

This pattern models the runbook's dedicated shared-services VNet as a platform-owned spoke. It reuses the workload-spoke composition for VNet, subnets, NSGs, route tables, hub peering, Private DNS links, diagnostics, RBAC, locks, identity, and optional Key Vault while keeping a separate platform workspace boundary.

Use this for platform-adjacent shared services only. Workload-specific resources should stay in workload spoke roots.
