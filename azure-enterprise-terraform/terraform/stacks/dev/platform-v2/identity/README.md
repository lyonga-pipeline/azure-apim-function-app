# Dev Platform V2 Identity

## Purpose

This stack is the shared identity-services landing zone for the `dev` platform
plane.

It owns reusable managed identities, the shared Key Vault, the shared
customer-managed key, and the identity spoke network that supports those
services.

For the broader design rationale, see `terraform/README-v2.md`.

## Why This Stack Exists

- Shared identities should not be recreated in every workload stack.
- Shared keys and shared secrets need a lifecycle separate from any one
  application.
- Identity services often need private network access and should be treated as
  platform assets.

## What This Stack Owns

- the identity resource group
- the identity spoke VNet and subnets
- shared Private DNS links into the platform connectivity plane
- the shared Key Vault
- reusable user-assigned managed identities
- the shared customer-managed key
- Key Vault private connectivity and diagnostics

## What It Reads From

- `platform-v2/connectivity` remote state
  - Uses hub networking and Private DNS information.
- `platform-v2/management` remote state
  - Uses the shared Log Analytics workspace for diagnostics.
- optional `global/subscriptions` remote state
  - Used for subscription validation.

## Subscription Catalog Mapping

This sample stack should use the `identity` entry in `global/subscriptions`.

That means:

- `subscription_catalog_entry_key = "identity"`
- `subscription_id` should eventually match the real identity subscription ID
  recorded in the central catalog

Why this matters:

- the identity stack is a shared platform service
- it should validate against the identity platform subscription, not a generic
  shared platform placeholder
- this keeps reusable identity assets in their own subscription boundary

## Main Inputs

- `subscription_id`
  - Makes the target subscription explicit and auditable.
- `location`
  - Defines where the shared identity services live.
- `resource_group_name`
  - Gives the identity plane a stable, separate resource boundary.
- VNet and subnet inputs
  - Define the identity spoke network that supports private access.
- `key_vault_name`
  - Names the shared Key Vault used by platform and workload consumers.
- shared identity name inputs
  - Define the reusable identities that downstream stacks can adopt.

## What This Stack Does

- creates the identity resource group
- creates the identity spoke VNet
- links that VNet into the central Private DNS zones
- peers the identity spoke back to the hub
- creates the shared Key Vault
- creates reusable user-assigned managed identities
- creates the shared CMK
- grants the required crypto permissions
- creates the Key Vault private endpoint
- sends Key Vault diagnostics to the shared workspace

## What Other Stacks Use From It

- workload stacks
  - Consume shared identities, the shared Key Vault, and the shared CMK.
- platform automation
  - Can use the shared identities and Key Vault for reusable platform tasks.

This stack is the shared identity provider for the rest of the platform.

## Main Building Blocks

- `module "tags"`
- `module "resource_group"`
- `module "identity_network"`
  - Creates the spoke VNet for shared identity services.
- `azurerm_private_dns_zone_virtual_network_link.identity_links`
  - Connects the identity VNet to the shared Private DNS zones.
- `module "hub_to_identity_peering"`
  - Connects the identity spoke back to the hub.
- `module "key_vault"`
  - Creates the shared private-by-default Key Vault.
- `module "shared_identities"`
  - Creates reusable user-assigned managed identities.
- `module "shared_services_cmk"`
  - Creates the shared customer-managed key.
- `module "role_assignments"`
  - Grants the required access to use the shared key.
- `module "key_vault_private_endpoint"`
- `module "key_vault_diagnostics"`

## Code Map

- `catalog-validation.tf`
  - Optional subscription catalog validation.
- `main.tf`
  - Creates the identity network, shared identities, Key Vault, and CMK.
- `outputs.tf`
  - Publishes shared identity and key outputs for downstream use.
- `dev.tfvars`
  - Supplies naming and address space choices for the environment.

## How To Extend It

- Add more shared identities when multiple workloads need the same access
  pattern.
- Keep app-specific identities in workload stacks unless they are truly shared.
- Publish reusable keys, secrets, and certificates through this platform
  Key Vault instead of duplicating them across workloads.

## Best-Practice Notes

This is the right boundary for long-lived reusable identity assets.

New engineers should think of this stack as the shared identity service layer
for the environment, not as an application stack. That makes it much easier to
decide what belongs here and what should stay workload-local.
