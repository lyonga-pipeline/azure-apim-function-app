# terraform-azurerm-compeer-private-dns-resolver

Azure Private DNS Resolver (`azurerm_private_dns_resolver`) plus its inbound /
outbound endpoints, forwarding rulesets, forwarding rules and ruleset VNet links —
each a keyed `map(object)`. The VNet and the dedicated resolver subnets are
caller-owned.

## Inputs (selected)

`name`, `resource_group_name`, `location`, `virtual_network_id`;
`inbound_endpoints`, `outbound_endpoints`, `forwarding_rulesets`,
`forwarding_rules`, `forwarding_ruleset_vnet_links` — all keyed maps.

## Outputs

`id`, `inbound_endpoint_ids`, `outbound_endpoint_ids`, `forwarding_ruleset_ids`,
plus composite maps.

## Lifecycle contract

Adding / removing an endpoint, ruleset, rule or link affects only that entry.
Forwarding-rule `domain_name` / `target_dns_servers` / `enabled`, `tags` →
**update in place**. `virtual_network_id`, endpoint `subnet_id` → **replace** the
resolver / endpoint.

State exposure: none.

## Tests

`terraform test` (offline): create.
