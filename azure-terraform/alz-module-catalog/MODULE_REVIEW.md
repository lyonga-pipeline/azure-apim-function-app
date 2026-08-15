# ALZ Module Readiness Review

## Review rules

This review applies the stricter rule requested for the final module pass:

- Ready = the module is present in the Compeer repo and is materially complete.
- Missing = the capability is required for the platform ALZ design but does not exist in the shared Compeer module directory.
- Incomplete = the module is still thin, placeholder, or not materially upgraded from the original source.

The platform design does not mark a row as Ready just because the module exists in the staging catalog; the Compeer repo walk is the source of truth.

## Ready

These modules are present in the Compeer module directory and are materially complete enough for a platform ALZ use case when called with approved enterprise defaults:

- `terraform-azurerm-compeer-resource-group`
- `terraform-azurerm-compeer-management-groups`
- `terraform-azurerm-compeer-management-locks`
- `terraform-azurerm-compeer-role-definition`
- `terraform-azurerm-compeer-role-assignments`
- `terraform-azurerm-compeer-user-assigned-identity`
- `terraform-azuread-compeer-ad-group`
- `terraform-azuread-compeer-ad-application`
- `terraform-azuread-compeer-service-principal`
- `terraform-azurerm-compeer-virtual-network`
- `terraform-azurerm-compeer-vnet-peering`
- `terraform-azurerm-compeer-network-security-group`
- `terraform-azurerm-compeer-route-table`
- `terraform-azurerm-compeer-subnet-route-table-association`
- `terraform-azurerm-compeer-nat-gateway`
- `terraform-azurerm-compeer-private-dns-zone`
- `terraform-azurerm-compeer-private-dns-vnet-link`
- `terraform-azurerm-compeer-private-dns-a-record`
- `terraform-azurerm-compeer-private-dns-resolver`
- `terraform-azurerm-compeer-private-endpoint`
- `terraform-azurerm-compeer-public-ip`
- `terraform-azurerm-compeer-load-balancer`
- `terraform-azurerm-compeer-application-gateway`
- `terraform-azurerm-compeer-log-analytics`
- `terraform-azurerm-compeer-diagnostic-settings`
- `terraform-azurerm-compeer-action-group`
- `terraform-azurerm-compeer-storage-account`
- `terraform-azurerm-compeer-storage-management-policy`
- `terraform-azurerm-compeer-keyvault`
- `terraform-azurerm-compeer-keyvault-assets`
- `terraform-azurerm-compeer-application-insights`
- `terraform-azurerm-compeer-app-configuration`
- `terraform-azurerm-compeer-apim`
- `terraform-azurerm-compeer-apim-api`
- `terraform-azurerm-compeer-apim-backend`
- `terraform-cloudflare-compeer-zone`
- `terraform-cloudflare-compeer-ruleset`
- `terraform-cloudflare-compeer-record-manager`

## Missing

These are required platform capabilities for the landing-zone design, but they do not presently exist as a real completed Compeer module to reuse directly:

- `subscription-vending` pattern and associated subscription lifecycle module
- `management-group policy` enforcement pattern for the full enterprise management-group roster
- `budget` pattern at management-group and subscription scale when the underlying Compeer repo is missing a complete variant
- `defender-soc-posture` or full Sentinel onboarding if the module remains not yet vendored in Compeer
- `palo-alto-hub` production VM-Series automation where the platform still depends on a local implementation and not on a reusable Compeer module
- any workload-owned app service, function app, app slot, or container module that is not yet published in the shared module repo

These rows should remain marked as Missing until the actual underlying Compeer module is present or a local implementation is intentionally added to the catalog with a matching file layout and lifecycle boundary.

## Incomplete

These modules are not acceptable as Ready under the stricter rule because they are placeholder, thin, or partially upgraded:

- modules that still contain `TODO` README stubs, empty implementation blocks, or generated examples without real resource logic
- `terraform-azurerm-compeer-keyvault-managed-storage-account`
- `terraform-azurerm-compeer-linux-web-app-slot`
- `terraform-azurerm-compeer-windows-function-app-slot`
- any catalog copy with a README that documents a feature but no real Terraform implementation or no matching file structure from the source directory

These should either be completed in place or moved to a clearly marked `incomplete` status instead of `Ready`.

## Key upgrade examples

### Key Vault

The key vault module is a good example of the required update pattern: it keeps the same Compeer file layout and resource lifecycle, but it upgrades the defaults to align with ALZ requirements.

The changes include:

- RBAC compatibility alongside the legacy access-policy path
- stronger defaults for purge protection and soft-delete retention
- private-first network ACL defaults
- explicit contacts and outputs for operational readiness
- no placeholder or hidden behavior that would make the module hard to reason about in a platform governance review

### Subscription pattern

The subscription-vending pattern is intentionally not marked Ready because the actual Compeer module directory does not contain a completed subscription-vending implementation. It remains a platform pattern that should be treated as Missing or local-only until there is a real vendorized module in the shared repo.

## Final recommendation

The catalog should only call a module Ready when:

1. the corresponding Compeer module exists in the Compeer repo,
2. the module carries the same file and folder design as the Compeer source,
3. the catalog implementation materially upgrades the code for ALZ readiness instead of only thinly wrapping it,
4. the module is not just a placeholder or README-only scaffold.

This is the rule that keeps the row status honest and prevents the earlier false `Ready` labeling.
