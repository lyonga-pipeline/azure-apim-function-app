# terraform-azurerm-compeer-azure-firewall

A single `azurerm_firewall`. AzureFirewallSubnet and the PIP(s) are caller-owned;
the firewall policy is passed in by ID (`firewall_policy_id`) — rules live in the
`firewall-policy` module, not here.

## Inputs (selected)

`name`, `resource_group_name`, `location`; `sku_name` (default `AZFW_VNet`),
`sku_tier` (default `Standard`); `ip_configurations` — `map(object({ subnet_id?,
public_ip_address_id }))`; `firewall_policy_id`, `zones`, `dns_servers`,
`threat_intel_mode`, `management_ip_configuration`.

## Outputs

`id`, `name`, `ip_configuration` (composite with private IPs).

## Lifecycle contract

`firewall_policy_id`, `dns_servers`, `threat_intel_mode`, `tags` → **update in
place**. `sku_name`, `sku_tier`, `zones`, `ip_configurations` subnet, `name` /
`rg` / `location` → **replace**.

State exposure: none.

## Tests

`terraform test` (offline): create.
