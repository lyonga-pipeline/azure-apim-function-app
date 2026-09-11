# Privileged Access

The IaC-appropriate slice of design-doc **Phase 2** (Privileged Identity
Management). Everything here follows "no standing privilege" — Terraform creates
**eligible** PIM assignments, never active ones, and the break-glass sign-in
alert.

## What is Terraform-managed here

| Object | Resource |
|---|---|
| PIM eligible role assignments (group → role → scope, activation via PIM) | `azurerm_pim_eligible_role_assignment` |
| PIM activation policy (approval, MFA-on-activation, max duration, notifications) | `terraform-azurerm-compeer-role-management-policy` |
| Break-glass account sign-in alert | `azurerm_monitor_scheduled_query_rules_alert_v2` |

Principals are the `AZ-*-Admins` groups from `platform-authorization`, not
individuals. `principal_id` therefore comes from that pattern's
`group_object_ids` output. Pair each `pim_eligible_role_assignments` entry with
a `role_management_policies` entry on the same `role_definition_id` + `scope`
so the eligibility and its activation rules are configured together.

## What is deliberately NOT here

`operational_contracts` carries the rest of Phase 2 with rationale:

- **break-glass accounts** — created and credentialed outside Terraform so tenant
  recovery survives broken IaC, identity-sync failure, or automation compromise.
- **admin Conditional Access** — tenant-wide, high lockout blast radius;
  portal-managed with a report-only rollout.
- **secure admin environment / PAW** — owned by the endpoint team.

## Dependencies

`log_analytics_workspace_id` (for the alert) comes from `platform-management`.
`principal_id` values come from `platform-authorization`.
