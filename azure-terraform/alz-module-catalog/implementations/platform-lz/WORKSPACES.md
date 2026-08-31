# Platform Workspace Catalog

## Deployment Order

1. `platform-governance` -> HCP workspace `platform-governance`
2. `platform-subscriptions` -> HCP workspace `platform-subscriptions`
3. `platform-policy` -> HCP workspace `platform-policy`
4. `platform-management` -> HCP workspace `platform-management`
5. `platform-connectivity` -> HCP workspace `platform-connectivity`
6. `platform-identity-security` -> HCP workspace `platform-identity-security`
7. `platform-hybrid-connectivity` -> HCP workspace `platform-hybrid-connectivity`
8. `platform-palo-alto` -> HCP workspace `platform-palo-alto`
9. `platform-directory-services` -> HCP workspace `platform-directory-services`
10. `platform-cloudflare-connectors` -> HCP workspace `platform-cloudflare-connectors`
11. `platform-shared-services` -> HCP workspace `platform-shared-services`
12. `platform-workload-spoke` -> template root for one workspace per workload/environment, such as `workload-spoke-internal-apps-prod`
13. `platform-network-peering` -> template root for one workspace per peering set, after the hub and spoke workspaces have applied
14. `platform-cloudflare-edge` -> optional Cloudflare-owned edge workspace

Steps 6 through 11 can run in parallel where their upstream outputs are already available and the operational approvals are complete.

## Output Contracts

`platform-governance` publishes:

- `management_group_ids`
- `custom_role_definition_ids`

`platform-policy` publishes:

- `custom_policy_definition_ids`
- `custom_policy_set_definition_ids`
- `management_group_policy_assignment_ids`
- `subscription_policy_assignment_ids`

`platform-subscriptions` publishes:

- `vended_subscription_ids`
- `platform_management_subscription_id`
- `platform_connectivity_subscription_id`
- `platform_identity_subscription_id`
- `platform_security_subscription_id`

`platform-management` publishes:

- `log_analytics_workspace_id`
- `log_analytics_workspace_guid`
- `action_group_id`
- `platform_storage_account_ids`
- `platform_key_vault_ids`
- `platform_key_vault_names`
- `platform_key_vault_uris`
- `platform_key_vault_private_endpoint_ids`
- `recovery_services_vault_ids`
- `data_collection_endpoint_ids`
- `data_collection_rule_ids`
- `data_collection_rule_association_ids`
- `sentinel_onboarding_id`

`platform-connectivity` publishes:

- `hub_virtual_network_id`
- `hub_virtual_network_name`
- `subnet_ids`
- `private_dns_zone_ids`
- `private_dns_zone_names`
- `private_dns_zone_resource_group_names`
- `bastion_id`
- `route_server_ids`
- `route_servers`
- `route_server_bgp_connections`
- `local_network_gateways`
- `network_watcher_flow_logs`

`platform-identity-security` publishes:

- `platform_identity_principal_ids`
- `key_vault_id`
- `key_vault_name`
- `key_vault_uri`
- `key_vault_private_endpoint_id`

`platform-hybrid-connectivity` publishes:

- `expressroute_circuit_ids`
- `expressroute_gateway_id`
- `expressroute_connection_ids`
- `expressroute_posture`
- `vpn_gateway_id`
- `local_network_gateway_ids`
- `vpn_connection_ids`
- `vpn_posture`

`platform-palo-alto` publishes:

- `marketplace_agreement_id`
- `bootstrap_storage_account_id`
- `public_ip_ids`
- `network_interface_ids`
- `load_balancer_ids`
- `virtual_machine_ids`
- `vendor_vmseries`

`platform-directory-services` publishes:

- `domain_controller_ids`
- `domain_controller_private_ips`
- `network_interface_ids`
- `data_disk_ids`
- `data_disk_attachment_ids`
- `ad_ds_role_install_extension_ids`
- `domain_join_extension_ids`
- `ad_ds_promotion_extension_ids`
- `operational_contracts`

`platform-cloudflare-connectors` publishes:

- `connector_vm_ids`
- `connector_vm_private_ips`
- `network_interface_ids`
- `operational_contracts`

`platform-shared-services` publishes:

- `shared_services_virtual_network_id`
- `subnet_ids`
- `private_endpoint_subnet_id`

`platform-cloudflare-edge` publishes:

- `zone_ids`
- `record_ids`
- `ruleset_ids`
- `tunnel_ids`
- `tunnel_cnames`
- `tunnel_dns_record_ids`
- `access_application_ids`
- `access_policy_ids`

Workload spoke roots publish:

- `spoke_virtual_network_id`
- `subnet_ids`
- `private_endpoint_subnet_id`
- `workload_identity_principal_id`
- `workload_key_vault_id`

## Dependency Rules

- Use `tfe_outputs` for declared output consumption.
- Use explicit workspace variables when an ID is supplied by an external owner or when it configures the provider subscription context.
- Do not use `terraform_remote_state` unless formally approved.
- Do not let two workspaces own the same Azure resource.
- Keep optional or cost-bearing resources behind the existing `enabled` flags or empty maps until approved.
