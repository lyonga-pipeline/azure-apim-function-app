# Azure Key Vault

This module creates a reusable Azure Key Vault resource. It models the vault lifecycle and commonly required vault-level configuration; consuming patterns decide how the vault is combined with private endpoints, diagnostics, RBAC assignments, secrets, keys, and certificates.

## ALZ catalog upgrade notes

This catalog copy keeps the Compeer module file layout and upgrades the implementation for enterprise landing-zone use:

- Uses `rbac_authorization_enabled` with a deprecated compatibility input for `enable_rbac_authorization`.
- Defaults purge protection to enabled and soft-delete retention to 90 days.
- Allows explicit `tenant_id`, defaulting to the active provider tenant when omitted.
- Supports keyed access policies through `access_policies_by_key` while keeping the previous `access_policies` list for compatibility.
- Models network ACLs as a single object with private-first defaults.
- Adds optional certificate contacts and composition-ready outputs for name, URI, tenant, SKU, location, resource group, RBAC mode, and private endpoint subresource names.

## Reusability and Extensibility

This module is designed as a reusable resource building block for Compeer platform and workload patterns:

- Resource-scoped ownership: the module models the Azure resource boundary, not a single application, environment, or landing-zone root.
- Pattern-ready interface: enterprise decisions such as naming, network placement, diagnostics, RBAC, private endpoints, and policy posture stay in the consuming pattern or root.
- Optional capability surface: optional Azure features are exposed through typed inputs, objects, maps, and empty defaults so consumers can enable them without forking the module.
- Stable identity for repeatable configuration: repeatable nested configuration uses keyed maps where identity matters, reducing unrelated replacement when an item is added or removed.
- Lifecycle-aware defaults: inputs favor provider-supported in-place updates and avoid generated names, positional indexes, or hidden defaults that create unnecessary replacement.
- Composition-ready outputs: IDs, names, endpoint details, and other downstream attributes are exported so dependent modules and HCP workspaces do not need to reconstruct implementation details.
- Backward-compatible growth: new capabilities should be added with optional inputs and sensible defaults; breaking input or output changes should be versioned deliberately.
- Validation focus: consumers should test create, no-change plan, in-place updates, optional feature add/remove, expected replacement cases, and destroy behavior before broad reuse.

Module-specific extension points: Vault settings, RBAC or access-policy mode, network ACLs, contacts, tenant selection, and timeouts are configurable while keys, secrets, certificates, private endpoints, diagnostics, and RBAC stay composable companion concerns.

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.2 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | >= 4.42, < 5.0 |

---

## Composition Boundary

Use companion modules for:

- `keyvault-assets`
- `key-vault-secret`
- `key-vault-key`
- `key-vault-certificate`
- `private-endpoint`
- `diagnostic-settings`
- `role-assignments`

Pattern and root modules should apply enterprise policy choices, such as RBAC-first authorization, private endpoint placement, diagnostics, and role assignments. This base module exposes valid Key Vault capabilities through optional typed inputs so new use cases do not require forking the module.
