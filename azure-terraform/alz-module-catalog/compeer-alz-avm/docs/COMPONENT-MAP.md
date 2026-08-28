# Component-to-Implementation Map

This map is based on workbook sheets 2 and 4. Microsoft AVM modules are used where they cover the resource. Compeer HCP modules from `../modules` are used where AVM coverage is missing, too thin for the workbook control, or explicitly required for Key Vault and Storage Account.

## Phase 1

| Components | Implementation |
|---|---|
| GOV-01, GOV-05, GOV-06, GOV-07, SEC-09, SEC-10 | `stacks/00-governance` with `Azure/avm-ptn-alz/azurerm` and Compeer policy baseline extension |
| GOV-03 | `stacks/05-subscription-vending` with `Azure/lz-vending/azurerm` |
| GOV-09 | Naming is encoded through stack locals and input contracts; Appendix naming remains a typed-input convention |
| GOV-10 | Compeer resource-group module in `stacks/06-subscription-baseline`; AVM resource groups in platform/network/workload stacks |
| GOV-12 | AVM MG role assignments in `00-governance`; Compeer role assignments in subscription/platform/workload stacks |
| GOV-15 | AVM lock interfaces where available; operational destroy procedure remains documented control |
| IAM-01 | `stacks/07-identity-groups` with `compeer-ad-group/azuread` |
| IAM-02 | `stacks/00-governance` with `compeer-role-definition/azurerm` |
| IAM-03 | `stacks/03-privileged-access` native `azurerm_pim_eligible_role_assignment` |
| IAM-04 | `stacks/03-privileged-access` sign-in alert plus operational contract for manual account creation |
| IAM-05 | `stacks/08-workload-identity` with Compeer AD app/SP modules and native federated credentials |
| IAM-06 | `stacks/30-workload-spoke` AVM user-assigned identity |
| IAM-07 | `stacks/22-directory-services` with Compeer NIC, Windows VM, domain-join, diagnostics, and AD promotion contract |
| IAM-08 | `stacks/03-privileged-access` operational contract for tenant Conditional Access validation |
| NET-01 | Version-controlled IPAM/CIDR inputs consumed by `20-connectivity` and `30-workload-spoke` |
| NET-02 to NET-08, NET-22 | `stacks/20-connectivity` AVM hub VNet, subnets, route tables, NSGs, and peering inputs |
| NET-10, NET-11, NET-36, NET-37 | `stacks/21-palo-alto` with Compeer storage, private endpoint, public IPs, NICs, diagnostics, and SNAT/bootstrap contracts |
| NET-12 | `stacks/21-palo-alto` operational contract for Panorama or Strata Cloud Manager onboarding |
| NET-13, NET-14 | `stacks/20-connectivity` AVM load balancers with HA-port rules |
| NET-15, NET-16 | AVM route-table and NSG modules in `20-connectivity` and `30-workload-spoke` |
| NET-18 | `stacks/20-connectivity` AVM ExpressRoute gateway |
| NET-19 | `stacks/24-expressroute` with Compeer ExpressRoute circuit and gateway connection modules |
| NET-23, NET-24 | `stacks/30-workload-spoke` spoke blueprint, repeated with prod/non-prod tfvars |
| NET-26 | `stacks/20-connectivity` AVM private DNS zone pattern |
| NET-27, NET-28 | `stacks/22-directory-services` DNS architecture and on-prem forwarder contracts |
| NET-29 | `stacks/25-private-endpoints`, plus embedded Compeer private endpoints in platform and workload stacks |
| NET-38 | Carrier/Equinix routing contract; no Azure object in scope |
| SEC-01 | `stacks/10-platform` Compeer Sentinel onboarding and `51-operations` production-authorization contract |
| SEC-02 | `stacks/10-platform` Sentinel base plus data-connector contract where provider coverage is incomplete |
| SEC-05 | `stacks/06-subscription-baseline` and `10-platform` Compeer Defender posture modules |
| SEC-07 | `stacks/10-platform` Compeer Key Vault, RBAC, diagnostics, private endpoint |
| SEC-12 | `stacks/20-connectivity` AVM Bastion |
| OBS-01 | `stacks/10-platform` AVM Log Analytics workspace |
| OBS-02, OBS-03 | Compeer diagnostic settings in platform/subscription/workload stacks plus governance DINE policy |
| PLT-01 | `stacks/10-platform` Compeer Recovery Services Vault and diagnostics |
| PLT-06 | `stacks/10-platform` Compeer Storage Account, diagnostics, private endpoints |
| IAC-01 to IAC-05, IAC-08 | `stacks/02-iac-foundation` HCP Terraform project/workspace/RBAC/registry/policy/run-trigger model and workflow contracts |
| IAC-07 | `stacks/06-subscription-baseline` subscription baseline composition |
| WKL-01 | `stacks/30-workload-spoke` AVM + Compeer HCP spoke blueprint |
| WKL-02 | Pilot workload is a validation activity consuming `30-workload-spoke`; no generic module is invented |
| DR-03 | Zone-aware inputs across `20-connectivity`, `21-palo-alto`, `22-directory-services`, and gateway stacks |

## Phase 2

| Components | Implementation |
|---|---|
| GOV-02, GOV-08, GOV-11, GOV-14 | `00-governance`/`06-subscription-baseline` inputs for dormant MGs, regulatory assignment, exemptions, and sandbox scope |
| GOV-04 | `05-subscription-vending` self-service vending path |
| GOV-13 | `06-subscription-baseline` native subscription budgets; Compeer budget module was not used because its management-group branch does not validate with the current AzureRM provider |
| NET-07, NET-25, NET-39 | Reuse `20-connectivity` and `30-workload-spoke` with partner/external-apps tfvars and routing contracts |
| NET-17 | `40-phase2-connectivity` Compeer network watcher flow logs with traffic analytics |
| NET-20, NET-21 | `40-phase2-connectivity` AVM VPN gateway, Compeer local network gateway, native IPsec connection |
| NET-30 | `40-phase2-connectivity` network watcher and native connection monitors |
| NET-31 | `40-phase2-connectivity` Compeer route server and BGP connections |
| NET-32 | `40-phase2-connectivity` AVM DDoS plan |
| NET-33, NET-34, NET-40 | `41-cloudflare-ingress` Compeer Cloudflare modules plus tunnel/Zero Trust/failover contracts |
| NET-35 | `40-phase2-connectivity` AVM Application Gateway and native WAF policy |
| SEC-03, SEC-04, SEC-06, SEC-11, SEC-13, SEC-14 | `51-operations` operational contracts and monitor modules; specific SOC content and JIT/rotation policies depend on SOC ownership |
| SEC-08 | `50-phase2-data-protection` AVM Disk Encryption Set |
| OBS-04 | `51-operations` Compeer action group and monitor metric alert modules |
| OBS-05 | `50-phase2-data-protection` Compeer log archive storage account and diagnostics |
| OBS-06, OBS-07, OBS-08 | `51-operations` contracts for AMA/DCRs, workbooks, and ITSM integration |
| PLT-03 | `50-phase2-data-protection` AVM Compute Gallery |
| PLT-04, PLT-05, PLT-08 | `51-operations` Update Manager, Change Tracking, and Arc contracts |
| PLT-07, DR-04 | `50-phase2-data-protection` Compeer DR Recovery Services Vault and diagnostics |
| IAC-06 | `02-iac-foundation` HCP drift/health-assessment contract |
| WKL-03 | `60-aks` AVM AKS production pattern |
| WKL-04 | `61-apim` AVM API Management |
| WKL-05 | `62-sql` AVM SQL server |
| WKL-06 | `63-avd` AVM AVD management plane |
| DR-01, DR-02 | Reuse `20-connectivity`, `24-expressroute`, and `30-workload-spoke` with East US 2 inputs and global peering/ER contracts |
| DR-05 | `51-operations` DR runbook/test contract |

## Sheet 4 Deployment-Order Additions

| Components | Implementation |
|---|---|
| GOV-16, GOV-17, GOV-18 | Management group and sandbox subscription placement through `00-governance`, `05-subscription-vending`, and `06-subscription-baseline` |
| IAM-09 | Federation-path validation remains an IAM-owned operational contract; no Azure landing-zone resource is created |
| IAC-09, IAC-10, IAC-12 | `02-iac-foundation` policy-set, run-trigger/output, and metadata-enrichment contracts |
| NET-41, NET-42 | Reserved hub subnets in `20-connectivity` tfvars |
| NET-43 | Shared-services VNet option is covered by `30-workload-spoke` if separated from the hub; otherwise `20-connectivity` shared-services subnet is used |
| NET-44 | Carrier and Equinix engagement is an operational prerequisite for `24-expressroute` |
| OBS-10, PLT-09 | Enterprise tooling reachability remains a firewall policy and agent deployment contract |
| WKL-07 | Workload Key Vault pattern in `30-workload-spoke` using Compeer Key Vault and private endpoint modules |
| WKL-08 | Sandbox spoke uses `30-workload-spoke` with sandbox subscription, policy, and routing inputs |
