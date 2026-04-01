# Global Role Assignments

## Purpose

This stack seeds the high-scope Azure RBAC assignments for the landing zone
pattern.

It is for central platform and governance access, not for application-local
permissions.

For the broader design rationale, see `terraform/README-v2.md`.

## Why This Stack Exists

- High-scope roles should be managed separately from workload-local RBAC.
- Platform teams need access before environment and workload stacks can run.
- Central RBAC is easier to audit when it is kept in one place.

## What This Stack Owns

- management-group and other centrally scoped role assignments
- the mapping between platform personas and Azure roles at high scope

## What It Reads From

- `global/management-groups` remote state
  - Uses management group IDs for assignment scope.
- direct principal ID inputs
  - Used to tell the stack which Entra groups, service principals, or managed
    identities should receive which roles.

## Main Inputs

- management group IDs
  - Define where each assignment should land.
- principal IDs
  - Identify the groups or identities that need central access.
- role mapping inputs
  - Tell the stack which personas should get contributor, reader, or admin
    rights.

## What This Stack Does

- reads the management group hierarchy
- validates that prerequisite branches exist
- builds a normalized assignment map
- creates the requested RBAC assignments only when the matching principal ID is
  supplied

Typical assignments in this stack are:

- platform deployer roles
- security reader roles
- shared nonprod workload operator roles
- shared prod reader roles

## Current Conditional Assignments

This stack only creates an assignment when the matching principal ID variable is
set to a non-empty value.

- if `platform_deployer_principal_id` is set, grant that principal
  `Contributor` and `User Access Administrator` on `platform`
- if `security_reader_principal_id` is set, grant that principal `Reader` on
  `security`
- if `nonprod_workload_deployer_principal_id` is set, grant that principal
  `Contributor` on `nonprod`
- if `prod_workload_reader_principal_id` is set, grant that principal `Reader`
  on `prod`

If those variables are left empty, this stack plans and applies successfully
but creates no RBAC assignments for that branch.

## Effective Access Model

These assignments are made at management-group scope, so Azure RBAC inheritance
applies to child management groups, subscriptions, resource groups, and
resources under that branch.

- `platform_deployer_principal_id`
  - gets `Contributor` and `User Access Administrator` on `platform`
  - can create, update, and delete resources in the `platform` branch
  - can manage RBAC assignments in the `platform` branch
  - because `connectivity`, `management`, `identity`, and `security` sit under
    `platform`, this principal inherits access to those child branches too
- `security_reader_principal_id`
  - gets `Reader` on `security`
  - can view resources in the `security` branch
  - cannot create, update, or delete resources in `security` unless another
    assignment grants write access
- `nonprod_workload_deployer_principal_id`
  - gets `Contributor` on `nonprod`
  - can create, update, and delete resources in the `nonprod` branch
  - cannot manage RBAC there because it does not receive `User Access Administrator`
- `prod_workload_reader_principal_id`
  - gets `Reader` on `prod`
  - can view resources in the `prod` branch
  - cannot create, update, or delete resources in `prod` unless another
    assignment grants write access

Reader access alone does not permit deployments.

With the current hierarchy:

- a principal that only has `Reader` on `prod` cannot deploy to `prod`
- a principal that only has `Reader` on `security` cannot deploy to `security`
- the `platform_deployer_principal_id` can deploy to `security` because
  `security` is a child of `platform`
- the `platform_deployer_principal_id` cannot deploy to `prod` based on this
  stack alone because `prod` is under the separate `landing_zones` branch
- the `nonprod_workload_deployer_principal_id` cannot deploy to `prod` based on
  this stack alone

## When This Stack Is Useful

- you have separate deployment identities for platform and workloads
- you want nonprod deployers to have write access but prod identities to be
  read-only
- you want security or audit identities to have centralized read access
- you want RBAC changes versioned, reviewed, and reproducible in Git instead of
  manual portal changes
- you expect multiple subscriptions under the same management-group branch and
  want inheritance

## When It May Be Unnecessary

- you have one Terraform OIDC principal
- its permissions are already managed outside Terraform
- your environment is small and you do not need separate
  platform/nonprod/prod/security identities
- you are not trying to codify RBAC as part of the landing zone

## What Other Stacks Use From It

This stack mostly serves the estate operationally rather than through data
outputs.

Its main effect is that:

- central deployers already have access before running platform stacks
- central readers already have visibility across the estate
- workload stacks do not need to bootstrap tenant-wide or management-group-wide
  access themselves

## Main Building Blocks

- `module "role_assignments"`
  - Creates the RBAC assignments from the computed map.
- `terraform_data.dependency_guard`
  - Stops planning if management group prerequisites are missing.

## Code Map

- `main.tf`
  - Reads management group state and builds the assignment map.
- `outputs.tf`
  - Publishes assignment IDs for audit and troubleshooting.
- `global.auto.tfvars`
  - Supplies principal IDs and assignment settings.

## How To Extend It

- Add new central personas here when the scope is truly management-group-wide
  or broader.
- Keep resource-group and resource-level RBAC in platform or workload stacks
  unless the access must be shared centrally.
- Review new assignments carefully because this stack has a large blast radius.

## Best-Practice Notes

This separation is important.

If high-scope RBAC and workload-local RBAC are mixed together, engineers have a
hard time understanding who owns access and why. Keeping central assignments in
this stack makes the access model much easier to explain and scale.

One more important constraint: this stack is for codifying ongoing RBAC, not
for self-bootstrapping an underprivileged deployment identity. The principal
running Terraform must already have enough rights to create these role
assignments at the target management-group scopes.
