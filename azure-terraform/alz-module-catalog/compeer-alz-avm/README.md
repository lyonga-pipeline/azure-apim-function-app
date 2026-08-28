# Compeer Azure Landing Zone - AVM + Compeer HCP composition

This repository implements the ALZ scope from `Azure_LZ_MVP_Component_List.xlsx`, sheets 2 and 4, as separate Terraform state boundaries. It uses Microsoft AVM modules first, Compeer HCP registry modules from the local catalog when AVM coverage is missing or insufficient, and native Terraform resources for provider-only controls.

Compeer module sources are written as private registry references, for example:

```hcl
source = "app.terraform.io/Compeer-Financial-Services/compeer-private-endpoint/azurerm"
```

Key Vault and Storage Account patterns intentionally use Compeer HCP modules as requested.

## Stack Boundaries

1. `00-governance` - ALZ management groups, ALZ policy, MG RBAC, custom roles, policy baseline
2. `02-iac-foundation` - HCP Terraform projects, workspaces, variable sets, registry modules, policy sets, run triggers
3. `03-privileged-access` - PIM eligible assignments and break-glass sign-in alerting
4. `05-subscription-vending` - platform, workload, sandbox, and self-service subscription vending
5. `06-subscription-baseline` - subscription RGs, activity logs, RBAC, policy, Defender, provider registration, budgets
6. `07-identity-groups` - Entra RBAC groups
7. `08-workload-identity` - Entra applications, service principals, and OIDC federated credentials
8. `10-platform` - management, security, monitoring, Key Vault, storage, Sentinel, Defender, backup vault
9. `20-connectivity` - Central US hub VNet, subnets, UDRs, NSGs, private DNS, DNS resolver, ER gateway, Palo ILBs, Bastion
10. `21-palo-alto` - Palo VM-Series Azure plumbing, bootstrap storage, NICs, public IPs, diagnostics, Panorama/SNAT contracts
11. `22-directory-services` - AD DS VM/NIC/disk deployment and AD DNS/promotion contracts
12. `24-expressroute` - ExpressRoute circuits, peerings, authorizations, gateway connections
13. `25-private-endpoints` - reusable Compeer private endpoint pattern
14. `30-workload-spoke` - workload spoke blueprint with VNet, subnets, NSGs, UDRs, peering, UAMI, workload Key Vault
15. `40-phase2-connectivity` - DDoS, backup VPN, local network gateways, Route Server, flow logs, connection monitors, App Gateway/WAF
16. `41-cloudflare-ingress` - Cloudflare zone, records, rulesets, and tunnel/Zero Trust/failover contracts
17. `50-phase2-data-protection` - DES/CMK, log archive storage, Compute Gallery, DR vault
18. `51-operations` - action groups, metric alerts, Sentinel content, AMA/DCR, workbooks, ITSM, Update Manager, Arc, DR runbooks
19. `60-aks` - production AKS pattern
20. `61-apim` - API Management pattern
21. `62-sql` - Azure SQL server pattern
22. `63-avd` - AVD management plane pattern and session-host/diagnostics contracts

Each stack includes an HCP backend example and `terraform.tfvars.example`. `REPLACE` and `REPLACE_ME` values are deployment contracts, not fabricated environment values.

## Deployment Order

Bootstrap and governance:

`00-governance` -> `02-iac-foundation` -> `05-subscription-vending` -> `06-subscription-baseline`

Identity and observability:

`07-identity-groups` -> `08-workload-identity` -> `03-privileged-access` -> `10-platform`

Connectivity and platform dependencies:

`20-connectivity` -> `21-palo-alto` -> `22-directory-services` -> `24-expressroute` -> `25-private-endpoints`

Workloads and Phase 2:

`30-workload-spoke` -> `40-phase2-connectivity` -> `41-cloudflare-ingress` -> `50-phase2-data-protection` -> `51-operations` -> `60-aks` / `61-apim` / `62-sql` / `63-avd`

## Validation Notes

Use Terraform `>= 1.12` for the full repo because `Azure/avm-ptn-alz/azurerm` `0.21.0` in `00-governance` requires it. Other stacks have lower minimums, but CI should standardize on `>= 1.12`.

Private Compeer HCP modules require registry credentials for direct `terraform init`. For local validation, rewrite the private registry sources to the adjacent `../modules` catalog and remove registry `version` arguments only in the temporary copy.

Some workbook rows are intentionally represented as operational contracts because they are not Azure resources or are high-blast-radius tenant/platform controls: break-glass account creation, Conditional Access, Panorama/Strata policy, on-prem DNS forwarders, carrier/Equinix work, Azure DevOps bootstrap, SOC tuning, and DR runbooks.
