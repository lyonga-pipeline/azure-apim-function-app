# Subscription Vending

This root vends Azure subscriptions and places them under the approved landing-zone management group hierarchy. It intentionally stays separate from `global-governance` so subscription billing lifecycle, management group and policy lifecycle, and workload deployment lifecycle can be operated independently.

## What It Does

- Creates Azure subscriptions through `azurerm_subscription`.
- Associates each vended subscription to the target management group with `azurerm_management_group_subscription_association`.
- Applies enterprise subscription tags from `default_tags` plus per-subscription tags.
- Keeps future trees such as regulated apps and shared services in the catalog with `enabled = false` until governance is approved.

## Safety Controls

`vending_enabled` defaults to `false`. No subscriptions are created unless this is set to `true`.

When enabling vending, provide either:

- `default_billing_scope_id` for all subscriptions, or
- `billing_scope_id` on each subscription entry that needs a different billing scope.

The root fails early if vending is enabled without a billing scope, with an unknown management group key, or with an invalid workload value.

## Management Group Assumption

This root expects the target management groups to already exist. Create and govern management groups in `global-governance`, then use this root to create and place subscriptions. For brownfield landing zones, set `management_group_id` in the catalog when the Azure management group name differs from the architecture key.

## Activation Pattern

Use the checked-in `terraform.tfvars.example` as the catalog baseline:

1. Copy the example into the workspace variable set or a real `terraform.tfvars` managed by the approved pipeline.
2. Set `subscription_id` to the execution subscription.
3. Set `default_billing_scope_id`.
4. Confirm which subscriptions should have `enabled = true`.
5. Set `vending_enabled = true`.
6. Run through HCP Terraform with governance and approval checks.

Keep the regulated-apps and shared-services subscriptions disabled until those trees are formally activated.
