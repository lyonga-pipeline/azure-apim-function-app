# Global Subscriptions

## Purpose

This stack is the central subscription catalog for the landing zone pattern.

It does not currently create Azure subscriptions. Its job is to describe which
subscriptions exist, what role each one plays, and which management group each
subscription should live under.

For the broader design rationale, see `terraform/README-v2.md`.

## Recommended Subscription Model

The recommended enterprise pattern in this repo is:

- one subscription for shared connectivity services
- one subscription for shared management services
- one subscription for shared identity services
- one subscription for shared security services when that function is split out
- one or more separate workload subscriptions for application landing zones
- optional separate subscriptions for sandbox and decommissioned use cases

This follows the Azure landing zone guidance that platform landing-zone
components should usually have their own subscriptions, while application
landing zones should use separate workload subscriptions by environment or
business boundary.

In plain language:

- `connectivity` is where shared networking lives
- `management` is where shared monitoring and recovery services live
- `identity` is where shared identity services live
- `security` is where shared security tooling can live
- `nonprod` and `prod` are where workload subscriptions should normally live

This is why the sample `global.auto.tfvars` now uses a separate catalog entry
for each platform component instead of a single shared `platform`
subscription.

## Recommended Catalog Entries

The current sample catalog is organized like this:

| Catalog key | Management group | Typical purpose | Main consumer |
| --- | --- | --- | --- |
| `connectivity` | `connectivity` | Hub networking, gateways, firewall, Private DNS | `stacks/*/platform-v2/connectivity` |
| `management` | `management` | Log Analytics, alerting, archive, recovery | `stacks/*/platform-v2/management` |
| `identity` | `identity` | Shared Key Vault, shared identities, shared keys | `stacks/*/platform-v2/identity` |
| `security` | `security` | Central security tooling and future security services | future security stack |
| `nonprod_finserv_api` | `nonprod` | Non-production workload landing zone | `stacks/*/workload-v2/finserv-api` |
| `prod_finserv_api` | `prod` | Production workload landing zone | future prod workload root |
| `sandbox_shared` | `sandbox` | Sandbox or experimentation subscriptions | sandbox workloads |
| `decommissioned_archive` | `decommissioned` | Retired or quarantined subscriptions | retirement workflows |

## Why Separate Subscriptions Are Better

Using dedicated subscriptions for platform components is usually the better
enterprise pattern because:

- ownership is clearer
- billing and quota boundaries are clearer
- least-privilege RBAC is easier to apply
- policy scope is easier to reason about
- outages and changes have a smaller blast radius
- one platform function can evolve without changing every other function

For example:

- the network team can manage `connectivity` without also owning monitoring
- the operations team can manage `management` without also owning shared keys
- workload teams can deploy to `nonprod` or `prod` subscriptions without being
  granted broad rights in platform subscriptions

## Why This Stack Exists

- It gives the project one source of truth for subscription IDs.
- It keeps management group placement out of individual platform and workload
  stacks.
- It lets governance stacks target subscriptions consistently instead of
  relying on hardcoded IDs in many places.
- It gives new engineers one place to understand the subscription model before
  reading the rest of the code.

## What This Stack Owns

This stack owns the subscription inventory only.

It does not create Azure resources. It creates normalized locals and outputs
that other stacks read through remote state.

## What It Reads From

- `var.target_subscriptions`
  - This is the main input to the stack.
  - Each entry describes one logical subscription role in the pattern.
  - Each entry tells the stack which management group that subscription should
    belong to.

## Main Inputs

- `target_subscriptions`
  - The source of truth for the subscription catalog.
  - Use this to add a new platform, workload, sandbox, or retired subscription
    role.
- `management_group_key`
  - Tells downstream governance stacks where the subscription belongs in the
    management group hierarchy.
- `existing_subscription_id`
  - The actual Azure subscription ID to attach.
  - It is trimmed to avoid failures caused by accidental whitespace.
  - It can be left blank in the sample catalog until the real subscription is
    available.
- `subscription_display_name`
  - Optional friendly name.
  - If not supplied, the stack falls back to the map key so downstream code
    still has a readable value.

## Important Note About Blank Subscription IDs

The sample `global.auto.tfvars` intentionally leaves most
`existing_subscription_id` values blank.

Why this is done:

- it keeps the repo safe to apply before subscription vending is complete
- it lets teams agree the target subscription model before assigning real IDs
- it prevents the management-group stack from trying to associate fake
  placeholder subscription IDs

How this works in the code:

- `normalized_subscriptions` still keeps the entry in the catalog
- `subscriptions_by_group` filters out blank IDs before publishing the group
  map used by `global/management-groups`

That means you can safely build the catalog structure first, then replace the
blank IDs later when the real subscriptions exist.

## How The Locals Work

### `normalized_subscriptions`

This local cleans and standardizes the raw input.

It makes sure downstream code can always expect:

- a `management_group_key`
- a trimmed `existing_subscription_id`
- a `subscription_display_name`

Why this matters:

- governance and platform stacks should not have to re-validate subscription
  input shape
- small input issues, like trailing spaces, should be fixed once in a central
  place

### `subscription_catalog`

This local is the normalized inventory that other stacks consume.

Right now it mirrors `normalized_subscriptions`, but keeping it separate makes
future extension easier. For example, you can later enrich the catalog with:

- environment
- cost center
- owner
- support team
- business unit

without changing the earlier normalization step.

### `subscriptions_by_group`

This local builds the reverse index that governance stacks need:

- `management_group_key => list(subscription_ids)`

Why this matters:

- management groups attach subscriptions by group, not by arbitrary catalog key
- policy and RBAC are often applied by management group branch
- this makes it easy to loop per management group instead of manually building
  lists in many places

## What Other Stacks Use From It

- `global/management-groups`
  - Uses `subscriptions_by_group` to attach subscriptions to the correct
    management groups.
- `global/policy`
  - Indirectly depends on this stack because policy assignments follow the
    management group structure built from this catalog.
- `global/role-assignments`
  - Indirectly depends on this stack for the same reason.
- `platform-v2/*` and `workload-v2/*`
  - Can validate that their explicit `subscription_id` matches the central
    subscription catalog.

Recommended downstream mapping for the current v2 roots:

- `platform-v2/connectivity` should use catalog key `connectivity`
- `platform-v2/management` should use catalog key `management`
- `platform-v2/identity` should use catalog key `identity`
- `workload-v2/finserv-api` should use catalog key `nonprod_finserv_api` in
  non-production environments and a `prod_*` key in production

## Main Building Blocks

- `locals`
  - Normalize, enrich, and group subscription metadata.
- `outputs`
  - Publish the catalog and group index to downstream stacks.

This stack is intentionally simple because it should be safe to apply early and
often.

## Code Map

- `main.tf`
  - Builds the normalized catalog and management-group index.
- `outputs.tf`
  - Publishes the catalog for downstream stacks.
- `global.auto.tfvars`
  - Defines the active subscription inventory for the project.
  - The sample file is now modeled after a CAF-style platform and landing-zone
    subscription layout.

## How To Extend It

- Add more metadata to each subscription entry when the organization grows.
- Keep this stack focused on subscription inventory and placement.
- If you later automate subscription creation, write the created subscription
  IDs back into this catalog before attaching them to management groups.

## Best-Practice Notes

This is a strong enterprise pattern because subscription ownership and
placement are explicit and auditable.

Without this stack, subscription IDs tend to get scattered across platform and
workload roots. That makes governance harder to scale and much harder for new
engineers to understand.

Helpful references used for this update:

- Thomas Maurer, "Prepare your Azure cloud environment with the Cloud Adoption Framework":
  https://www.thomasmaurer.ch/2023/07/prepare-your-azure-cloud-environment-with-the-cloud-adoption-framework/
- Microsoft Azure landing zones overview:
  https://learn.microsoft.com/azure/cloud-adoption-framework/ready/landing-zone/
- Microsoft guidance on application environments and subscriptions:
  https://learn.microsoft.com/azure/cloud-adoption-framework/ready/landing-zone/design-area/management-application-environments
