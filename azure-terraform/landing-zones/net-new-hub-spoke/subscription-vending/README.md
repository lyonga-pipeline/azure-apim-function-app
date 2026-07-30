# Subscription Vending

This root vends Azure subscriptions and places them under the approved landing-zone management group hierarchy. It intentionally stays separate from `global-governance` so subscription billing lifecycle, management group and policy lifecycle, and workload deployment lifecycle can be operated independently.

## What It Does

- Creates Azure subscriptions through `azurerm_subscription`.
- Associates each vended subscription to the target management group with `azurerm_management_group_subscription_association`.
- Applies enterprise subscription tags from `default_tags` plus per-subscription tags.
- Keeps the full go-live subscription catalog in `terraform.tfvars`, with actual creation gated by `vending_enabled`.

## Safety Controls

`vending_enabled` defaults to `false`. No subscriptions are created unless this is set to `true`.

When enabling vending, provide either:

- Microsoft Customer Agreement billing parts: `billing_account_name`, `billing_profile_name`, and `invoice_section_name`;
- `default_billing_scope_id` when passing the full billing scope directly; or
- `billing_scope_id` on each subscription entry that needs a different billing scope.

The root fails early if vending is enabled without a billing scope, with an unknown management group key, or with an invalid workload value.

## Management Group Assumption

This root expects the target management groups to already exist. Create and govern management groups in `global-governance`, then use this root to create and place subscriptions. For brownfield landing zones, set `management_group_id` in the catalog when the Azure management group name differs from the architecture key.

## Go-Live Footprint

The checked-in catalog matches the current landing-zone diagram for the new enterprise tree:

- 25 management group keys under `compeer-enterprise-mg`.
- 48 subscription entries across platform, internal apps, external apps, regulated apps, shared services, sandbox, and decommissioned groups.

The existing `compeer-mg` branch shown outside this tree is treated as an existing landing-zone path and is not vended by this root.

## Activation Pattern

Use the checked-in `terraform.tfvars` as the catalog baseline:

1. Set `subscription_id` to the execution subscription used by the run identity.
2. Set `tenant_id` to the target Microsoft Entra directory.
3. Set the full `billing_account_name`, plus `billing_profile_name` and `invoice_section_name`, or set `default_billing_scope_id` directly.
4. Confirm which subscriptions should have `enabled = true`.
5. Confirm each `management_group_key` points to the correct existing management group.
6. Set `vending_enabled = true`.
7. Run through HCP Terraform with governance and approval checks.

## Client Environment Changes

When deploying this root for a client environment, update these values first:

- `subscription_id`: the existing execution subscription where the Terraform run identity can authenticate.
- `tenant_id`: the client's Microsoft Entra tenant/directory ID from the Azure portal Advanced tab.
- `billing_account_name`: the full billing account `name`, not the display name. In the portal this appears under Billing account and can be copied from Cost Management + Billing or queried through the Billing API/CLI.
- `billing_profile_name`: the client billing profile name, such as `BARQ-ROVI-BG7-PGB`.
- `invoice_section_name`: the client invoice section name, such as `MRM-PUUU-PJA-PGB`.
- `default_billing_scope_id`: leave blank for Microsoft Customer Agreement when using the three billing fields above; set it directly for EA or non-standard billing scopes.
- `management_groups`: keep the keys aligned to the architecture, but set `management_group_id` when a client uses different physical management group names.
- `subscriptions`: adjust subscription names, `workload` values, tags, and `enabled` flags for the approved rollout batch.
- `default_tags`: replace owner, repo, workspace, cost center, data classification, and compliance values with the client's enterprise standards.
- `vending_enabled`: keep `false` until billing, governance, and approval are complete; set `true` only for an approved vending run.

The Terraform run identity must have permission to create subscriptions at the billing scope. For a Microsoft Customer Agreement this is typically owner/contributor on the invoice section, billing profile, or billing account, or Azure subscription creator on the invoice section. It also needs permission to associate subscriptions to the target management groups.

The Azure portal's Subscription owner field is not exposed by the current `azurerm_subscription` resource. Assign owners after vending through the approved RBAC/bootstrap process for each new subscription.
