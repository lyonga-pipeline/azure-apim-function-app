# ALZ Module Readiness Review

## Ready To Use With WAF Inputs

These modules are good starting points for the platform ALZ when called with enterprise defaults for tags, diagnostics, network restrictions, RBAC, and encryption:

- `terraform-azurerm-compeer-resource-group`
- `terraform-azurerm-compeer-management-groups`
- `terraform-azurerm-compeer-management-locks`
- `terraform-azurerm-compeer-policy-baseline`
- `terraform-azurerm-compeer-role-assignments`
- `terraform-azurerm-compeer-role-definition`
- `terraform-azurerm-compeer-user-assigned-identity`
- `terraform-azuread-compeer-ad-group`
- `terraform-azuread-compeer-ad-application`
- `terraform-azuread-compeer-service-principal`
- `terraform-azurerm-compeer-virtual-network`
- `terraform-azurerm-compeer-vnet-peering`
- `terraform-azurerm-compeer-network-security-group`
- `terraform-azurerm-compeer-route-table`
- `terraform-azurerm-compeer-subnet-route-table-association`
- `terraform-azurerm-compeer-nat-gateway`
- `terraform-azurerm-compeer-private-dns-zone`
- `terraform-azurerm-compeer-private-dns-vnet-link`
- `terraform-azurerm-compeer-private-dns-a-record`
- `terraform-azurerm-compeer-private-dns-resolver`
- `terraform-azurerm-compeer-private-endpoint`
- `terraform-azurerm-compeer-expressroute-circuit`
- `terraform-azurerm-compeer-virtual-network-gateway`
- `terraform-azurerm-compeer-virtual-network-gateway-connection`
- `terraform-azurerm-compeer-local-network-gateway`
- `terraform-azurerm-compeer-route-server`
- `terraform-azurerm-compeer-public-ip`
- `terraform-azurerm-compeer-load-balancer`
- `terraform-azurerm-compeer-application-gateway`
- `terraform-azurerm-compeer-azure-firewall`
- `terraform-azurerm-compeer-firewall-policy`
- `terraform-azurerm-compeer-ddos-protection-plan`
- `terraform-azurerm-compeer-bastion-host`
- `terraform-azurerm-compeer-log-analytics`
- `terraform-azurerm-compeer-diagnostic-settings`
- `terraform-azurerm-compeer-action-group`
- `terraform-azurerm-compeer-monitor-metric-alert`
- `terraform-azurerm-compeer-network-watcher-flow-logs`
- `terraform-azurerm-compeer-recovery-services-vault`
- `terraform-azurerm-compeer-storage-account`
- `terraform-azurerm-compeer-storage-container-immutability-policy`
- `terraform-azurerm-compeer-storage-management-policy`
- `terraform-azurerm-compeer-key-vault`
- `terraform-azurerm-compeer-key-vault-key`
- `terraform-azurerm-compeer-key-vault-secret`
- `terraform-azurerm-compeer-key-vault-certificate`
- `terraform-azurerm-compeer-apim-service`
- `terraform-azurerm-compeer-application-insights`
- `terraform-azurerm-compeer-app-configuration`
- `terraform-azurerm-compeer-operational-contracts`
- `terraform-cloudflare-compeer-zone`
- `terraform-cloudflare-compeer-record-manager`
- `terraform-cloudflare-compeer-ruleset`

## Ready But Disabled By Default

These codify the contract now but must stay disabled until cost, SOC onboarding, and runbook ownership are approved:

- `terraform-azurerm-compeer-defender-soc-posture`
- `terraform-azurerm-compeer-sentinel`
- `terraform-azurerm-compeer-palo-alto-hub`
- `terraform-cloudflare-compeer-edge-baseline`

## Needs Fix Before Direct HCP Reuse

These registry modules or copied sources need remediation before being treated as the enterprise baseline:

- `terraform-azurerm-compeer-networking`: useful reference only. It is too monolithic for ALZ ownership boundaries and includes provider configuration and hardcoded DNS defaults. Split into VNet, subnet, NSG, route-table, DNS, diagnostics, and watcher modules.
- `terraform-azurerm-compeer-private-endpoint`: original HCP source hides drift with broad `ignore_changes`. Use the staged catalog version instead.
- `terraform-azurerm-compeer-keyvault`: original HCP source defaults are weak for financial workloads. Use the staged catalog version with RBAC, purge protection, 90-day retention, private endpoints, and diagnostics.
- `terraform-azurerm-compeer-budget`: original HCP source is resource-group oriented. Add subscription and management-group budget support before using for platform guardrails.
- `terraform-cloudflare-compeer-ruleset`: staged copy fixes the rule type and nested matched-data iterator. Republish after validation.
- `terraform-azurerm-compeer-route-tables`, `terraform-azurerm-compeer-network-security-group`, `terraform-azurerm-compeer-nat-gateway`, and similar older modules: remove module-local provider blocks and add examples before promotion.
- Empty repos: `terraform-azurerm-compeer-keyvault-managed-storage-account`, `terraform-azurerm-compeer-linux-web-app-slot`, and web/function app slot repos need implementations or retirement decisions.

## Workload-Landing-Zone Modules

The following registry modules are better classified as workload modules, not platform ALZ modules:

- Function apps, app slots, web apps, App Service plans, containers, AKS/Container Apps, API Management, Service Bus, Event Grid, SQL, Synapse, Data Factory, Data Lake, application storage, Linux VMs, Windows VMs, and domain join.

Platform ALZ may provide shared controls for these workloads, but the resource lifecycles belong to workload landing zones or application compositions.
