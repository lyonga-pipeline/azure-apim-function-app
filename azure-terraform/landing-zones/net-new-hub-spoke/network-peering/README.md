# Network Peering Root

This root owns the cross-subscription network attachment between one hub VNet and one workload spoke VNet. It creates both Azure peering resources and links shared Private DNS zones to the spoke VNet.

Keep this in a dedicated HCP workspace, for example `network-peering-online-banking-np1`. Do not also enable `hub_connection` in `workload-spoke` for the same spoke, because only one state should own each peering resource.

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

The `platform-connectivity` workspace must publish:

- `hub_resource_group_name`
- `hub_virtual_network_name`
- `hub_virtual_network_id`
- `resource_group_name`

The `workload-spoke` workspace must publish:

- `spoke_resource_group_name`
- `spoke_virtual_network_name`
- `spoke_virtual_network_id`

This pattern is preferred over duplicating IDs manually in every consumer workspace. It keeps the platform and workload states isolated while exposing only declared outputs through the HCP Terraform API.

For `tfe_outputs` to work, the peering workspace needs an HCP Terraform token with read access to the producer workspace outputs. Set a sensitive environment variable named `TFE_TOKEN` if your HCP run environment does not already provide one. Use a team token or service account token with the narrowest practical read access to `platform-connectivity` and `workload-spoke`.

Do not enable broad remote state sharing for this pattern. Remote state sharing is mainly for `terraform_remote_state`, which reads from state snapshots. `tfe_outputs` is preferred because it reads declared outputs through the HCP Terraform API instead of granting backend-level state access.

Manual variables remain as an override/fallback. Set `use_tfe_outputs = false` and provide the values directly if output sharing is not available.

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

The HCP run identity needs network permissions in both subscriptions:

- `Network Contributor` on the hub VNet or hub network resource group.
- `Network Contributor` on the spoke VNet or spoke network resource group.
- `Private DNS Zone Contributor` on the hub Private DNS zone resource group.

The Azure dynamic credential or federated credential must cover this workspace for both plan and apply phases.
