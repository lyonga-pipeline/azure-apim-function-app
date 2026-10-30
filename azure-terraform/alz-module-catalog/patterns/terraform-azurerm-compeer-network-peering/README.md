# Network Peering HCP Adapter

## Overview

**What this deploys:** the cross-subscription VNet peering + Private DNS
zone links between one hub and one workload spoke. This HCP-output
adapter delegates Azure resources to the pure hub-spoke-peering pattern.
The spoke blueprint publishes a versioned contract and creates no attachments.
The central workspace calls this adapter, which retains legacy input compatibility.

| Resource | Purpose |
|---|---|
| `azurerm_virtual_network_peering` (module, aliased `hub`/`spoke` providers) | The two-way peering |
| `azurerm_private_dns_zone_virtual_network_link` (module) | Links the hub's shared Private DNS zones to the spoke VNet |
| `terraform_data.resolved_input_validation` | See below |

**`terraform_data.resolved_input_validation` — why resolution is checked
before use:** this pattern can source hub/spoke identifiers either from
explicit variables or from `tfe_outputs` (another workspace's state). A
stale or unreadable `tfe_outputs` source would otherwise plan a peering
against `null` resource IDs; the contract fails the plan cleanly instead.
See `tests/contracts.tftest.hcl`.

---

This root owns the cross-subscription network attachment between one hub VNet and one workload spoke VNet. It creates both Azure peering resources and links shared Private DNS zones to the spoke VNet.

The [peering standard](../../implementations/platform-lz/PEERING-STANDARD.md)
selects environment-and-hub/network-boundary workspaces for multiple approved
spokes, with per-spoke workspaces reserved for justified exceptions. This adapter
still handles **one pair**, not an attachments map. The new
[AzAPI batch pattern](../terraform-azapi-compeer-network-attachments/README.md)
and independent environment roots implement that grouping using full parent IDs;
dynamic AzureRM provider-alias selection in for_each is not supported.
Existing single-pair callers remain compatible. Do not describe this interface
as the completed environment rollout or change deployed state ownership implicitly.
Central does not mean one global state or a tenant-wide identity. Set
use_spoke_attachment_contract=true to consume the spoke's public versioned
contract and required DNS links. For version 2, this adapter calls the pinned
naming module centrally; the spoke supplies context, not attachment names.
Missing/incompatible contracts or
competing ownership fail; gateway intent requires matching explicit approval.
Do not enable legacy hub_connection for the same pair. Each resource has one owner.
See [ATTACHMENT.md](../../implementations/workload-lz/ATTACHMENT.md) before
adopting this for existing spoke-owned resources.

The azurerm.dns alias now targets the actual existing DNS subscription. In the
platform-network-peering root, set optional private_dns_subscription_id when
DNS is outside the hub subscription; null retains the previous hub default.
Direct callers of this adapter must supply hub, spoke and dns provider aliases.
Set each zone's actual resource_group_name or the correct shared default.
The adapter now reads nonsensitive_values only; sensitive .values never fill
missing public contracts. Azure names remain unchanged unless explicitly
overridden. Moved blocks preserve existing internal peering/link addresses;
review an actual plan for moves, not replacements, before upgrading a live state.

## Inputs

By default this root consumes upstream HCP Terraform workspace outputs with `tfe_outputs`. Set these as Terraform variables in the peering workspace:

- `tenant_id` only when not supplied by the HCP Azure dynamic credential set. Leave it unset for normal HCP dynamic credential runs.
- `hub_subscription_id`
- `spoke_subscription_id`
- `tfe_organization`, defaults to `lyonga-org`
- `platform_connectivity_workspace_name`, defaults to `platform-connectivity`
- `workload_spoke_workspace_name`, defaults to `workload-spoke`
- `peering_name_prefix`, defaults to `online-banking-np1`

Do not rename `terraform.tfvars.example` to `terraform.tfvars` in this root. HCP Terraform automatically loads checked-in `terraform.tfvars` files, and placeholder values can override missing workspace variables.

In contract mode, connectivity must publish hub_virtual_network_id and the
spoke must publish attachment_contract after a successful apply. DNS metadata
comes from that contract. Version 2 contains naming_context (region, environment,
domain and appcode), not peering_names or DNS link_name. The central naming call
uses the actual hub/spoke VNet names to generate the same canonical names as
before. Version 1 published names remain supported without renaming.
Central peering_names and private_dns_link_names overrides can preserve approved
custom Azure names during migration; unknown DNS override keys fail the plan.
Optional explicit contract input is supported for isolated/manual deployment,
with the same ownership validation.

In legacy input mode, the `platform-connectivity` workspace must publish:

- `hub_resource_group_name`
- `hub_virtual_network_name`
- `hub_virtual_network_id`
- `resource_group_name`

The `workload-spoke` workspace must publish:

- `spoke_resource_group_name`
- `spoke_virtual_network_name`
- `spoke_virtual_network_id`

Published IDs avoid uncontrolled duplication, but outputs are not authorization.
Cross-check them against the network-approved Git inventory before permitting
attachment. Hub/spoke VNets remain exclusively in their foundation states;
only peerings and approved links belong to the attachment owner. Required hub
route changes, spoke UDRs and Panorama policies stay with their current owners.

## Why `TFE_TOKEN` is used

The peering workspace uses the `tfe_outputs` data source to read declared outputs from the `platform-connectivity` and `workload-spoke` workspaces. HCP Terraform can run the Azure providers with dynamic Azure credentials, but the TFE provider still needs an HCP Terraform API credential when it reads outputs from other workspaces.

Set a sensitive environment variable named `TFE_TOKEN` in the peering workspace when the run environment does not already provide a token with enough HCP Terraform permissions. Use a team token or service account token with the narrowest practical read access to the producer workspaces.

This token is not an Azure credential and does not grant access to Azure resources. It is only used by the TFE provider to read HCP Terraform metadata, specifically the declared outputs that the peering root needs.

Do not enable broad remote state sharing for this pattern. Remote state sharing is mainly for `terraform_remote_state`, which reads from state snapshots. `tfe_outputs` is preferred because it reads declared outputs through the HCP Terraform API instead of granting backend-level state access.

In contract mode, manual operation requires use_tfe_outputs=false plus an
approved spoke_attachment_contract; it does not silently fall back to partial
VNet IDs. In legacy mode only, explicit variables retain their old behavior.

Manual fallback example:

```hcl
use_tfe_outputs = false

hub_resource_group_name  = "<platform-connectivity output: hub_resource_group_name>"
hub_virtual_network_name = "<platform-connectivity output: hub_virtual_network_name>"
hub_virtual_network_id   = "<platform-connectivity output: hub_virtual_network_id>"

spoke_resource_group_name  = "<workload-spoke output: spoke_resource_group_name>"
spoke_virtual_network_name = "<workload-spoke output: spoke_virtual_network_name>"
spoke_virtual_network_id   = "<workload-spoke output: spoke_virtual_network_id>"

peering_name_prefix = "online-banking-np1"

private_dns_zone_resource_group_name = "<platform-connectivity output: resource_group_name>"

private_dns_zones = {
  app_service   = { name = "privatelink.azurewebsites.net" }
  key_vault     = { name = "privatelink.vaultcore.azure.net" }
  storage_blob  = { name = "privatelink.blob.core.windows.net" }
  storage_queue = { name = "privatelink.queue.core.windows.net" }
  storage_file  = { name = "privatelink.file.core.windows.net" }
}
```

For initial smoke tests, leave gateway transit disabled:

```hcl
hub_to_spoke = {
  allow_forwarded_traffic = true
  allow_gateway_transit   = false
  use_remote_gateways     = false
}

spoke_to_hub = {
  allow_forwarded_traffic = true
  allow_gateway_transit   = false
  use_remote_gateways     = false
}
```

After ExpressRoute or VPN gateway is deployed in the hub, set `hub_to_spoke.allow_gateway_transit = true` and `spoke_to_hub.use_remote_gateways = true` for spokes that should use the hub gateway.

## Permissions

The HCP run identity needs narrowly scoped lifecycle permissions on both approved
VNets and the exact DNS zones. Prefer security-reviewed custom roles including
necessary VNet/peering read, create/update/delete and peer/join actions, plus
required DNS-link operations. Write-only is insufficient; subscription-wide
Owner/Network Contributor is not required merely for attachment.

The Azure dynamic credential or federated credential must cover this workspace for both plan and apply phases.

For the target grouped model, security reviews the union of approved VNet/zone
grants for each environment/hub principal; shared-hub grants are not isolated to
one peering child. Prefer separate plan/apply principals and verify every alias.
Serialize peering mutations both within a batch and across workspaces sharing
the hub; pair dependencies and state locks alone are insufficient. See the
standard for pipeline gates, route ownership, identity exceptions and migration.
