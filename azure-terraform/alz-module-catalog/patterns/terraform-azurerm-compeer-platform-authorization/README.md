# Platform Authorization

The Entra **authorization foundation** for the landing zone: the security groups
that are the only principals ever granted Azure RBAC, their role assignments at
management-group scope, and (rarely) custom role definitions.

Implements design-doc **Phase 1 Step 5** (Entra security group framework),
**Phase 3 Step 4** (Azure RBAC framework) and **Phase 3 Step 5** (map Entra
groups to Azure roles). The governing principle is `User -> Group -> Role ->
Scope` — no user is assigned a role directly.

## What is Terraform-managed here

| Object | Module |
|---|---|
| Entra security groups (`AZ-<domain>-<tier>`) | `terraform-azuread-compeer-ad-group` |
| Group-to-role-to-scope assignments (the RBAC matrix) | `terraform-azurerm-compeer-role-assignments` |
| Custom role definitions (kept minimal) | `terraform-azurerm-compeer-role-definition` |

Providers: `azuread` (groups) + `azurerm` (role definitions / assignments). Run
this with an identity that has **directory write** (group creation) and
**User Access Administrator** at the target management-group scope.

## What is deliberately NOT here

Declared in `operational_contracts` with rationale — break-glass accounts,
cloud-only admin account provisioning, Conditional Access, PIM activation-policy
settings, and joiner/mover/leaver + access reviews. See
`implementations/platform-lz/IDENTITY-RBAC-IAC-BOUNDARY.md` for the full map.

Group **membership** is intentionally not asserted here by default: leave
`members` empty and let identity governance own it, so a Terraform run never
removes a person's access. Terraform still owns the group object and its RBAC.

## Outputs

`group_object_ids` feeds subscription- and workload-scope RBAC in
`subscription-onboarding` / `workload-spoke`. `manual_control_keys` lists the
controls that live outside Terraform.
