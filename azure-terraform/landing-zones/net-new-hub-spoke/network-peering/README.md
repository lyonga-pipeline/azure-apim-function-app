# Network Peering Root

This root owns the cross-subscription network attachment between one hub VNet and one workload spoke VNet. It creates both Azure peering resources and links shared Private DNS zones to the spoke VNet.

Keep this in a dedicated HCP workspace, for example `network-peering-online-banking-np1`. Do not also enable `hub_connection` in `workload-spoke` for the same spoke, because only one state should own each peering resource.

## Inputs

Set these as Terraform variables in the peering workspace:

- `tenant_id`
- `hub_subscription_id`
- `spoke_subscription_id`
- `hub_resource_group_name`
- `hub_virtual_network_name`
- `hub_virtual_network_id`
- `spoke_resource_group_name`
- `spoke_virtual_network_name`
- `spoke_virtual_network_id`
- `peering_name_prefix`
- `private_dns_zone_resource_group_name`
- `private_dns_zones`

Use outputs from `platform-connectivity` for the hub VNet and Private DNS names. Use outputs from `workload-spoke` for the spoke VNet.

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
