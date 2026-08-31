# Subscription Vending

> ## ⛔ NOT DEPLOYED — reference only
>
> At Compeer, subscriptions are **provisioned by the CSP partner**, not by
> Terraform. New subscriptions appear under the Tenant Root Group and are then
> placed and RBAC'd by the
> [`subscription-onboarding`](../terraform-azurerm-compeer-subscription-onboarding)
> pattern.
>
> This pattern (which *creates* subscriptions via `azurerm_subscription`) is kept
> for reference and for the day Compeer moves to an EA/MCA billing model where
> Terraform-driven vending is possible. **Do not wire it into a live workspace.**
> The `platform-subscriptions` implementation is hard-disabled
> (`enabled = false`, `vending_enabled = false`) and must stay that way.

This root vends Azure subscriptions and places them under the approved landing-zone management group hierarchy. It intentionally stays separate from `global-governance` so subscription billing lifecycle, management group and policy lifecycle, and workload deployment lifecycle can be operated independently.

## What It Does

- Creates Azure subscriptions through `azurerm_subscription`.
- Associates each vended subscription to the target management group with `azurerm_management_group_subscription_association`.
- Creates optional subscription-scope RBAC assignments through the shared `role-assignments` module.
- Applies enterprise subscription tags from `default_tags` plus per-subscription tags.
- Keeps the full target subscription catalog in `terraform.tfvars`, with actual creation gated by `vending_enabled` and per-subscription `enabled` flags.

## Safety Controls

`vending_enabled` defaults to `false`. No subscriptions are created unless this is set to `true`.

When enabling vending, provide either:

- Microsoft Customer Agreement billing parts: `billing_account_name`, `billing_profile_name`, and `invoice_section_name`;
- `default_billing_scope_id` when passing the full billing scope directly; or
- `billing_scope_id` on each subscription entry that needs a different billing scope.

The root fails early if vending is enabled without a billing scope, with an unknown management group key, or with an invalid workload value.

`subscription_role_assignments` defaults to `{}`. Populate it only after the client's Entra groups or managed identities are approved. Assign privileged roles to groups, use PIM for eligibility where required, and avoid direct user assignments.

## Management Group Assumption

This root expects the target management groups to already exist. Create and govern management groups in `global-governance`, then use this root to create and place subscriptions. For brownfield landing zones, set `management_group_id` in the catalog when the Azure management group name differs from the architecture key.

## Go-Live Footprint

The checked-in catalog matches the current landing-zone diagram for the new enterprise tree:

- 25 management group keys under `compeer-enterprise-mg`.
- 48 subscription entries across platform, internal apps, external apps, regulated apps, shared services, sandbox, and decommissioned groups.
- 27 Phase 1 subscription entries are eligible when `vending_enabled = true`.
- 21 regulated-apps and shared-services entries are Phase 2 dormant and have `enabled = false`.

The existing `compeer-mg` branch shown outside this tree is treated as an existing landing-zone path and is not vended by this root.

## Activation Pattern

Use the checked-in `terraform.tfvars` as the catalog baseline:

1. Set `subscription_id` to the execution subscription used by the run identity.
2. Set `tenant_id` to the target Microsoft Entra directory.
3. Set the full `billing_account_name`, plus `billing_profile_name` and `invoice_section_name`, or set `default_billing_scope_id` directly.
4. Confirm which subscriptions should have `enabled = true`; leave Phase 2 regulated-apps and shared-services entries disabled until those branches are approved.
5. Confirm each `management_group_key` points to the correct existing management group.
6. Add subscription bootstrap RBAC in `subscription_role_assignments` for approved owner, contributor, reader, or automation groups.
7. Set `vending_enabled = true`.
8. Run through HCP Terraform with governance and approval checks.

## Client Environment Changes

When deploying this root for a client environment, update these values first:

- `subscription_id`: the existing execution subscription where the Terraform run identity can authenticate.
- `tenant_id`: the client's Microsoft Entra tenant/directory ID from the Azure portal Advanced tab.
- `billing_account_name`: the full billing account `name`, not the display name. In the portal this appears under Billing account and can be copied from Cost Management + Billing or queried through the Billing API/CLI.
- `billing_profile_name`: the client billing profile name, such as `BARQ-ROVI-BG7-PGB`.
- `invoice_section_name`: the client invoice section name, such as `MRM-PUUU-PJA-PGB`.
- `default_billing_scope_id`: leave blank for Microsoft Customer Agreement when using the three billing fields above; set it directly for EA or non-standard billing scopes.
- `management_groups`: keep the keys aligned to the architecture, but set `management_group_id` when a client uses different physical management group names.
- `subscriptions`: adjust subscription names, `workload` values, tags, and `enabled` flags for the approved rollout batch. Keep future branches disabled until the client approves their lifecycle.
- `subscription_role_assignments`: add client Entra group or managed identity object IDs for subscription owners, operators, readers, automation identities, and break-glass access as approved by IAM.
- `default_tags`: replace owner, repo, workspace, cost center, data classification, and compliance values with the client's enterprise standards.
- `vending_enabled`: keep `false` until billing, governance, and approval are complete; set `true` only for an approved vending run.

The Terraform run identity must have permission to create subscriptions at the billing scope. For a Microsoft Customer Agreement this is typically owner/contributor on the invoice section, billing profile, or billing account, or Azure subscription creator on the invoice section. It also needs permission to associate subscriptions to the target management groups.

The Azure portal's Subscription owner field is not exposed by the current `azurerm_subscription` resource. Use `subscription_role_assignments` to grant approved subscription-scope RBAC after vending, including owner-equivalent groups where required by the operating model.
