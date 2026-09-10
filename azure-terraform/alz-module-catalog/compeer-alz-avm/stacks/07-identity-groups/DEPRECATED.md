# DEPRECATED — 07-identity-groups

Superseded by the active platform tree:

- **`implementations/platform-lz/workspaces/platform-authorization`**
  (pattern `patterns/terraform-azurerm-compeer-platform-authorization`)

That workspace creates the Entra RBAC security groups **and** their
management-group-scope role assignments and custom roles, using the local
`terraform-azuread-compeer-ad-group` + `terraform-azurerm-compeer-role-assignments`
modules instead of the pinned registry modules used here.

`operational_contracts` moved to
`terraform-azurerm-compeer-operational-contracts`.

Boundary map (IaC vs. manual, all 10 design-doc phases):
`implementations/platform-lz/IDENTITY-RBAC-IAC-BOUNDARY.md`.

Do not add new configuration here.
