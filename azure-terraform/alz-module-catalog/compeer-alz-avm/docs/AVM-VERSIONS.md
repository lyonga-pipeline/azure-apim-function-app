# Module Version Pins

These are the module pins used by this repository. Private Compeer modules are referenced through the HCP private registry namespace `app.terraform.io/Compeer-Financial-Services`.

## Microsoft AVM / Microsoft Modules

| Module | Pin |
|---|---:|
| Azure/avm-ptn-alz/azurerm | 0.21.0 |
| Azure/lz-vending/azurerm | 7.0.3 |
| Azure/avm-res-resources-resourcegroup/azurerm | 0.4.0 |
| Azure/avm-res-authorization-roleassignment/azurerm | 0.3.1 |
| Azure/avm-res-managedidentity-userassignedidentity/azurerm | 0.5.2 |
| Azure/avm-res-operationalinsights-workspace/azurerm | 0.5.1 |
| Azure/avm-res-network-virtualnetwork/azurerm | 0.19.0 |
| Azure/avm-res-network-networksecuritygroup/azurerm | 0.5.1 |
| Azure/avm-res-network-routetable/azurerm | 0.5.0 |
| Azure/avm-res-network-loadbalancer/azurerm | 0.5.0 |
| Azure/avm-ptn-vnetgateway/azurerm | 0.10.3 |
| Azure/avm-ptn-network-private-link-private-dns-zones/azurerm | 0.23.2 |
| Azure/avm-res-network-dnsresolver/azurerm | 0.8.0 |
| Azure/avm-res-network-bastionhost/azurerm | 0.9.0 |
| Azure/avm-res-network-ddosprotectionplan/azurerm | 0.3.0 |
| Azure/avm-res-network-applicationgateway/azurerm | 0.5.2 |
| Azure/avm-res-compute-diskencryptionset/azurerm | 0.1.1 |
| Azure/avm-res-compute-gallery/azurerm | 0.2.1 |
| Azure/avm-ptn-aks-production/azurerm | 0.5.0 |
| Azure/avm-res-apimanagement-service/azurerm | 0.9.0 |
| Azure/avm-res-sql-server/azurerm | 0.2.1 |
| Azure/avm-ptn-avd-lza-managementplane/azurerm | 0.3.2 |

## Compeer HCP Modules

| Module | Pin |
|---|---:|
| compeer-action-group/azurerm | 1.0.0 |
| compeer-ad-application/azuread | 1.0.7 |
| compeer-ad-group/azuread | 1.0.0 |
| compeer-defender-soc-posture/azurerm | 1.0.0 |
| compeer-diagnostic-settings/azurerm | 1.0.0 |
| compeer-expressroute-circuit/azurerm | 1.0.0 |
| compeer-keyvault/azurerm | 1.0.6 |
| compeer-local-network-gateway/azurerm | 1.0.0 |
| compeer-monitor-metric-alert/azurerm | 1.0.0 |
| compeer-network-interface/azurerm | 1.0.0 |
| compeer-network-watcher-flow-logs/azurerm | 1.0.0 |
| compeer-operational-contracts/azurerm | 1.0.0 |
| compeer-policy-baseline/azurerm | 1.0.0 |
| compeer-private-endpoint/azurerm | 1.0.5 |
| compeer-public-ip/azurerm | 1.0.0 |
| compeer-recovery-services-vault/azurerm | 1.0.0 |
| compeer-resource-group/azurerm | 1.0.0 |
| compeer-role-assignments/azurerm | 1.0.0 |
| compeer-role-definition/azurerm | 1.0.0 |
| compeer-route-server/azurerm | 1.0.0 |
| compeer-sentinel/azurerm | 1.0.0 |
| compeer-service-principal/azuread | 1.0.1 |
| compeer-storage-account/azurerm | 1.3.3 |
| compeer-virtual-network-gateway-connection/azurerm | 1.0.0 |
| compeer-windows-vm/azurerm | 1.0.0 |
| compeer-windows-vm-domain-join/azurerm | 1.0.0 |
| compeer-zone/cloudflare | 1.0.3 |
| compeer-record-manager/cloudflare | 1.0.2 |
| compeer-ruleset/cloudflare | 1.0.3 |

## Intentional Fallbacks

`Azure/avm-ptn-lz-vending/azurerm` from the workbook is represented by the currently used Microsoft module `Azure/lz-vending/azurerm`.

The workbook-named custom role definition AVM is not used. Custom roles are implemented with `compeer-role-definition/azurerm`.

Recovery Services Vaults use `compeer-recovery-services-vault/azurerm`. The current AVM vault releases validated locally with null-sensitive validation issues for this composition.

Subscription budgets use native `azurerm_consumption_budget_subscription`. The local `compeer-budget` module has a management-group budget branch that does not validate with the current AzureRM provider schema even when the stack only needs subscription budgets.

Use Terraform `>= 1.12` for the complete repository because `Azure/avm-ptn-alz/azurerm` `0.21.0` requires it.
