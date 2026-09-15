# Workload Spoke Root

## Overview

**What this deploys:** the template every application workload's network
boundary is instantiated from — resource group, spoke VNet, subnets,
optional NSG/route-table associations, optional hub peering, optional
Private DNS links, and an optional per-workload Key Vault.

**`workload_key_vault`'s `network_acls` — why it's built field-by-field
instead of one `coalesce()`:** the same pattern as `platform-identity`'s Key
Vault (see that README) — building the final object with
`try(var.workload_key_vault.network_acls.<field>, <default>)` per field
avoids a `coalesce()` crash ("all arguments must have the same type") when
`network_acls` is left unset, which is the common case for a workload that
just wants Key Vault defaults. `tests/defaults.tftest.hcl`'s middle run is
the direct regression test.

---

This root creates an application landing-zone network boundary.

It deploys the workload resource group, spoke VNet, subnets, optional NSG/route-table associations, optional spoke-to-hub peering, and optional Private DNS links. Application resources should be deployed from the app-owned consumer repo using the explicit outputs from this root and the shared platform workspaces.

Use one workspace per workload and environment. Workload spokes should consume platform outputs such as hub VNet ID, Private DNS zone names, Log Analytics workspace ID, and approved route targets through HCP variables or variable sets.

For a new workload subscription, grant the HCP Azure run identity access before the first apply. This root creates the resource group, networking resources, and management locks, so a smoke-test deployment should use `Contributor` at the workload subscription scope. The workspace `subscription_id` must match that subscription, and the Azure dynamic credential/federated credential must cover the workspace run phases.

When the dedicated `network-peering` root owns hub/spoke attachment, keep `hub_connection = null` here. That avoids splitting the two peering directions across different states.

This root is a better OPA test target than `global-governance` because it creates taggable network resources and approved local module calls. For negative policy tests, temporarily use an unapproved region, remove required tag inputs, add a public IP, or introduce a PaaS resource with public network access in a branch.
