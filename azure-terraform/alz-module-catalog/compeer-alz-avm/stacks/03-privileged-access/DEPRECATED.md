# DEPRECATED — 03-privileged-access

Superseded by the active platform tree:

- **`implementations/platform-lz/workspaces/platform-privileged-access`**
  (pattern `patterns/terraform-azurerm-compeer-privileged-access`)

Same content — `azurerm_pim_eligible_role_assignment` (no standing privilege) and
the break-glass sign-in `azurerm_monitor_scheduled_query_rules_alert_v2` — with
the PIM principals resolved from the `platform-authorization` workspace's
`group_object_ids` output.

`operational_contracts` (break-glass accounts, PIM activation policy, admin
Conditional Access, secure admin environment) moved to
`terraform-azurerm-compeer-operational-contracts`.

Boundary map: `implementations/platform-lz/IDENTITY-RBAC-IAC-BOUNDARY.md`.

Do not add new configuration here.
