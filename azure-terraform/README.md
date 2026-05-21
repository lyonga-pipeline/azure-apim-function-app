# Azure Terraform Catalog

This catalog is the decoupled replacement for the mixed-lifecycle module estate reviewed from the screenshots, governance documents, and rationale write-ups.

## Design Rules

- One module owns one primary lifecycle boundary.
- Base modules keep inseparable resource configuration only.
- Base modules should carry resource-level enterprise standards such as secure defaults, validation, TLS posture, protocol posture, and standard tag contracts.
- Base modules should not contain hidden environment or platform intelligence such as subscription lookup, subnet inference, DNS inference, shared workspace inference, or resiliency-tier inference.
- RBAC, diagnostics, private connectivity, child objects, and workload-specific extensions are separate companion modules wherever Azure models them as separate resources or where ownership commonly differs.
- Repeated children use `map(object(...))` instead of ordered lists.
- Optional singleton blocks use `object(...)` plus `null`.
- Modules are written so application teams compose capabilities by calling specific components rather than cloning per-app variants.

## Enterprise Baseline Applied

These modules are intended to be opinionated about the resource they manage, but not magical about the environment they run in.

- Resource standards live in the base module.
  Examples: `public_network_access_enabled = false`, `https_only = true`, `minimum_tls_version = "1.2"`, disabled FTP/legacy publishing auth, RBAC-first Key Vault posture, secure storage defaults, and APIM protocol hardening.
- Environment standards live in the application root or pattern layer.
  Examples: which subnet ID to use, which private DNS zone to use, which shared Log Analytics workspace to use, which subscription a workload targets, or which shared APIM instance an application should bind to.
- Overrides are allowed, but they should be visible in the root contract rather than hidden inside module internals.

An audit pass was also applied across `azure-terraform/modules` to keep hidden environment logic out of the catalog. The modules do not take `environment` or `app_code` as base-module control inputs, and they do not internally resolve shared infrastructure identifiers from environment names.

## Catalog Layout

### Shared Companions

- `resource-group`
- `user-assigned-identity`
- `public-ip`
- `app-service-plan`
- `role-assignments`
- `diagnostic-settings`
- `private-endpoint`
- `private-dns-zone`
- `private-dns-vnet-link`
- `private-dns-a-record`

### Compute And App Platform

- `availability-set`
- `windows-vm`
- `windows-vm-data-disks`
- `windows-vm-domain-join`
- `windows-vm-extension`
- `function-app`
- `function-app-slot`
- `web-app`
- `web-app-slot`
- `app-service-vnet-integration`
- `container-agent`

### Data, Security, And Analytics

- `key-vault`
- `key-vault-access-policy`
- `key-vault-managed-hsm`
- `key-vault-secret`
- `key-vault-key`
- `key-vault-certificate`
- `storage-account`
- `storage-account-customer-managed-key`
- `storage-container`
- `storage-container-immutability-policy`
- `storage-blob`
- `storage-queue`
- `storage-table`
- `storage-share`
- `storage-management-policy`
- `sql-server`
- `sql-server-extended-auditing-policy`
- `sql-server-security-alert-policy`
- `sql-database`
- `synapse-workspace`
- `synapse-workspace-aad-admin`
- `synapse-filesystem`

### Networking And Edge

- `virtual-network`
- `route-table`
- `subnet-route-table-association`
- `network-security-group`
- `nsg-subnet-association`
- `network-interface`
- `nsg-network-interface-association`
- `network-interface-application-security-group-association`
- `nat-gateway`
- `nat-gateway-associations`
- `nat-gateway-public-ip-association`
- `vnet-peering`
- `load-balancer`
- `application-gateway`

### Integration And API Platform

- `apim-service`
- `apim-custom-domain`
- `apim-api`
- `apim-api-policy`
- `apim-backend`
- `apim-named-value`
- `apim-policy`
- `apim-product`
- `apim-product-api`
- `eventgrid-topic`
- `eventgrid-subscription`

### Observability And Operations

- `log-analytics`
- `application-insights`
- `action-group`

## Recommended Composition Model

A complete workload should normally be assembled from:

- one base platform resource module
- one or more generic companion modules such as `role-assignments`, `diagnostic-settings`, and `private-endpoint`
- child modules only where the workload genuinely owns child objects such as `key-vault-secret`, `storage-container`, `sql-database`, `apim-api`, or `eventgrid-subscription`
- association modules where ownership differs between the base resource and the attachment point, such as `nsg-subnet-association`, `subnet-route-table-association`, or `app-service-vnet-integration`

## Intentional Lifecycle Boundaries

The remaining "stitches" in this catalog are deliberate lifecycle seams, not gaps in the module set. They exist to keep base resources stable while allowing teams to change access, networking, child data objects, and workload configuration without replacing or overloading the core platform resource.

### Base Resource Vs Post-Provision Configuration

- `windows-vm` owns the VM, NIC reference, OS disk, identity, and availability decision.
- `windows-vm-domain-join`, `windows-vm-data-disks`, and `windows-vm-extension` remain separate because domain membership, disk layout, and guest bootstrap are workload- and operations-driven lifecycles.
- `web-app` and `function-app` own the site itself and inseparable app-service-native settings, while `web-app-slot`, `function-app-slot`, and `app-service-vnet-integration` remain separate because slot rollout and network attachment often change on a different cadence than the app.

### Control Plane Vs Data Plane Or Child Objects

- `key-vault` owns the vault resource, but `key-vault-secret`, `key-vault-key`, and `key-vault-certificate` stay separate because secret and key material changes far more often than vault policy or network posture.
- `storage-account` owns the account, but `storage-container`, `storage-blob`, `storage-queue`, `storage-table`, and `storage-share` remain separate because application-owned data-plane objects should not be coupled to account lifecycle.
- `sql-server` owns the server, while `sql-database` remains separate because databases are application-level tenants with their own sizing, retention, and release cadence.
- `synapse-workspace` owns the workspace, while `synapse-filesystem` and `synapse-workspace-aad-admin` stay separate because storage namespaces and admin assignment are separate operational concerns.
- `eventgrid-topic` and `eventgrid-subscription` are intentionally separate because publishers and subscribers are usually owned by different teams and deploy on different timelines.

### Base Resource Vs Security And Governance Attachments

- `role-assignments` is kept generic and separate because access changes are frequent, often centrally owned, and should not force base resource changes.
- `diagnostic-settings` stays separate because telemetry routing commonly varies by environment, platform standard, or central observability ownership.
- `sql-server-extended-auditing-policy` and `sql-server-security-alert-policy` are separate because compliance controls evolve independently of the SQL server itself.
- `storage-account-customer-managed-key`, `storage-management-policy`, and `storage-container-immutability-policy` remain separate because encryption, lifecycle retention, and immutability are governance controls that may be introduced or tightened after the base account exists.

### Base Network Objects Vs Attachments And Associations

- `virtual-network`, `route-table`, and `network-security-group` remain independent base resources.
- `subnet-route-table-association`, `nsg-subnet-association`, `nsg-network-interface-association`, and `network-interface-application-security-group-association` are deliberate stitches because subnet and NIC attachment ownership often differs from the base object owner.
- `nat-gateway`, `nat-gateway-associations`, and `nat-gateway-public-ip-association` stay separate so egress strategy and public IP assignment can change without rebuilding the NAT gateway or subnet.
- `private-endpoint`, `private-dns-zone`, `private-dns-vnet-link`, and `private-dns-a-record` remain composable because private connectivity and DNS are frequently owned by a shared networking team rather than by the application module owner.
- `vnet-peering` stays separate because peering is a relationship lifecycle between two networks, not a property of one network alone.

### Base Service Vs Service Content Or Consumer-Specific Configuration

- `apim-service` owns the APIM instance, while `apim-custom-domain`, `apim-api`, `apim-backend`, `apim-named-value`, `apim-policy`, `apim-api-policy`, `apim-product`, and `apim-product-api` remain separate because hostname management, API publishing, and consumer packaging change independently of the gateway runtime.
- `application-gateway` keeps inseparable nested routing and TLS blocks in one resource because Azure models them inside the gateway resource, but it still composes with shared modules like `public-ip`, `role-assignments`, and `diagnostic-settings`.

### What This Means For Consumers

- If a concern is modeled as a child object, attachment, association, access policy, or operational control, expect to compose it with the base module rather than expect it inside the base module.
- If a concern is an inseparable nested block on the Azure resource itself, it belongs in the base module so consumers do not need parallel variants.
- The goal is not zero composition. The goal is to remove unnecessary custom forks while preserving safe lifecycle separation.

## Validation Notes

The modules are structured to be broad enough for varied application needs without needing separate web-app or function-app variants, while still keeping coupling low. Optional features that Azure exposes as nested properties remain in the owning resource module. Separate resources and ownership-sensitive concerns remain outside the base module.

Notable breadth added to reduce downstream stitching:

- `web-app` and `function-app` now include richer site configuration, sticky settings, and first-class `auth_settings_v2` support.
- `application-gateway` now supports companion routing and TLS building blocks such as certificates, redirect configurations, rewrite rule sets, URL path maps, and WAF configuration.
- `eventgrid-subscription` now supports advanced filters, labels, retry policy, managed identities for delivery and dead-lettering, and delivery property headers.
- Storage governance and encryption concerns are covered with `storage-account-customer-managed-key`, `storage-management-policy`, and `storage-container-immutability-policy`.
- SQL security policy lifecycles are separated into `sql-server-extended-auditing-policy` and `sql-server-security-alert-policy`.
- APIM hostname and certificate ownership is handled separately through `apim-custom-domain`.

The catalog was formatted and then validated module-by-module against the installed AzureRM provider schema so the checked-in contracts match the provider surface in this environment.
