# DEPRECATED — 08-workload-identity

Superseded by the active platform tree:

- **`implementations/platform-lz/workspaces/platform-workload-identity`**
  (pattern `patterns/terraform-azurerm-compeer-workload-identity`)

Same shape — app registration + service principal + federated identity
credentials — plus SP role assignments and the 20-FIC-per-app limit enforced as
a variable validation. Uses the local `terraform-azuread-compeer-ad-application`
and `terraform-azuread-compeer-service-principal` modules.

Boundary map: `implementations/platform-lz/IDENTITY-RBAC-IAC-BOUNDARY.md`.

Do not add new configuration here.
