# Compeer Shared Services Pattern

This pattern models the runbook's dedicated shared-services VNet as a platform-owned spoke. It reuses the workload-spoke composition for VNet, subnets, NSGs, route tables, hub peering, Private DNS links, diagnostics, RBAC, locks, identity, and optional Key Vault while keeping a separate platform workspace boundary.

Use this for platform-adjacent shared services only. Workload-specific resources should stay in workload spoke roots.
