/*
================================================================================
COMPEER FINANCIAL - AZURE LANDING ZONE IMPLEMENTATION RUNBOOK (Terraform-first)
File: test-updated.tf

Purpose
-------
This file is an implementation-oriented deployment sequence derived from:
  - Azure Landing Zone Architecture & Design Document v7 (August 2026)
and supplemented only where the design document leaves an implementation gap.

This is intentionally a deployment/runbook file rather than a directly runnable
single Terraform root. The landing zone MUST be split into multiple HCP Terraform
roots/workspaces and lifecycle-aligned modules. Do not place the whole landing
zone in one state.

DOCUMENTED TARGET STATE
-----------------------
Primary region: Central US
Future DR region: East US 2
Network: Hub/spoke
Firewall: Palo Alto VM-Series HA pair (NOT Azure Firewall)
Hybrid connectivity: ExpressRoute primary, Site-to-Site VPN backup
Public ingress: Cloudflare Tunnel for external-apps only
Identity: Entra ID + existing on-prem AD; domain controllers remain hub-hosted
DNS: Centralized private DNS in hub + bidirectional hybrid DNS forwarding
Observability: Azure Monitor -> Log Analytics -> Sentinel is mandatory
Execution: Azure DevOps validation + HCP Terraform authoritative plan/apply

IMPORTANT IMPLEMENTATION RULE
-----------------------------
Terraform owns Azure/control-plane infrastructure where technically appropriate.
OS/domain promotion, Palo Alto operational policy, and any vendor configuration
that is not approved as Terraform-authoritative must remain in the owning team's
configuration-management/control plane.

===============================================================================
0. REQUIRED DEPLOYMENT BOUNDARIES
===============================================================================

Recommended HCP Terraform project:
  alz-platform

Recommended platform workspaces / roots:
  1. alz-governance
  2. alz-management
  3. alz-connectivity
  4. alz-identity
  5. alz-policy
  6. alz-shared-services        (only when required/activated)

Do NOT create a separate workspace merely because a resource type exists.
Create a workspace where ownership, lifecycle, blast radius, credentials,
recovery, or apply permissions justify a separate state boundary.

Suggested repo roots:

platform-alz/
  governance/
  management/
  connectivity/
  identity/
  shared-services/
  policy/

Policy/OPA may live in a separate repository if that is the approved control
plane pattern.

Cross-workspace contract:
  - Upstream platform roots publish explicit approved outputs.
  - Downstream roots consume explicit IDs/remote-state outputs.
  - Do not rediscover critical dependencies by broad name lookups.
  - Never let two workspaces own the same Azure resource.

===============================================================================
1. BOOTSTRAP / CONTROL-PLANE PREREQUISITES
===============================================================================

1.1 Reuse existing enterprise control planes
--------------------------------------------
ADO:
  - Reuse existing ADO organization/project.
  - Create only new ALZ platform repository/repositories.
  - Inherit existing project-level branch policies.
  - Seed validation YAML into main.
  - No develop branch is required for the platform ALZ roots.

HCP Terraform:
  - Reuse existing HCP organization.
  - Create a new project for the ALZ.
  - Create platform workspaces mapped to main + working directories.
  - Reuse approved agent pools, OAuth/VCS connection, and organization-level
    variable sets only where appropriate.
  - Use project-scoped variable sets for new-LZ-only settings.
  - Critical workspaces/projects should be protected from accidental destroy.

1.2 Authentication
------------------
Preferred:
  HCP Terraform dynamic credentials / workload identity federation to Azure.

Avoid:
  - Long-lived Azure client secrets when federation is available.
  - One global Owner/Contributor identity for all platform domains.
  - Secrets committed in tfvars or repo files.

Separate deployment identities at minimum by:
  - governance/policy
  - connectivity
  - identity
  - management
where the current operating model permits.

1.3 Required pre-build inputs
-----------------------------
DO NOT start resource deployment until these are confirmed:
  [ ] Platform subscription IDs
  [ ] Management-group IDs / tenant root permissions
  [ ] Approved Central US IPAM allocations
  [ ] On-prem CIDRs
  [ ] ExpressRoute provider / peering location / authorization details
  [ ] VPN public endpoints, ASN/BGP details, shared-key handling
  [ ] Palo Alto license model/SKU, approved PAN-OS release, VM size
  [ ] Palo Alto NIC model (3 vs 4 dataplane/HA interfaces) and LB design
  [ ] Panorama onboarding details
  [ ] Cloudflare account/zone and API ownership model
  [ ] Cloudflare connector egress destinations and firewall allowlist
  [ ] AD domain name, existing DNS servers, site/subnet design
  [ ] DC static IPs and AD team promotion/replication procedure
  [ ] Log Analytics / Sentinel targets
  [ ] Naming/tagging values and mandatory governance tags

===============================================================================
2. GOVERNANCE FOUNDATION - alz-governance
===============================================================================

2.1 Create new management-group hierarchy
-----------------------------------------
Target hierarchy:

Tenant Root
├── compeer-mg                     # existing legacy LZ - DO NOT RECREATE
└── compeer-enterprise-mg          # new LZ
    ├── platform-mg
    │   ├── security-mg
    │   ├── identity-mg
    │   ├── management-mg
    │   └── connectivity-mg
    ├── workloads-mg
    │   ├── internal-apps-mg       # active at launch
    │   ├── external-apps-mg       # active at launch
    │   ├── regulated-apps-mg      # future/dormant
    │   └── shared-services-mg     # future/dormant
    ├── sandbox-mg
    └── decommissioned-mg

Terraform:
  azurerm_management_group
  azurerm_management_group_subscription_association

Important:
  "Dormant" means present in the target hierarchy but not used until the
  governance trigger described in the architecture is met.

2.2 Associate platform subscriptions
------------------------------------
  sub-connectivity-prod-cus -> connectivity-mg
  sub-identity-prod-cus     -> identity-mg
  sub-security-prod-cus     -> security-mg
  sub-management-prod-cus   -> management-mg

2.3 RBAC
--------
Use Entra security groups and management-group/subscription inheritance.

Terraform where approved:
  azuread_group
  azurerm_role_assignment

Do not assign normal platform access directly to individual users.
PIM/eligible assignment implementation must follow the identity design and the
provider/API capability approved by the Identity team.

2.4 Azure Policy
----------------
Initial mode:
  Audit / DoNotEnforce where the control needs proving.

Promote to Deny only after:
  - false-positive review
  - exception path is ready
  - current ALZ resources comply
  - rollback/recovery path exists

Minimum policy themes:
  - allowed region
  - required tags
  - public exposure restrictions
  - private endpoints/public-network restrictions where required
  - diagnostics
  - TLS/encryption
  - Defender
  - approved SKUs/images
  - naming where technically enforceable

===============================================================================
3. MANAGEMENT / OBSERVABILITY FOUNDATION - alz-management
===============================================================================

Deploy before production-critical network services where practical because
observability is a production authorization gate.

Terraform:
  - management resource group(s)
  - Log Analytics workspace
  - Microsoft Sentinel onboarding
  - Azure Monitor resources
  - action groups
  - Data Collection Endpoints / DCRs where required
  - Recovery Services Vault
  - diagnostic-policy infrastructure
  - Bastion / central management tooling only if approved by the architecture

Mandatory target:
  Azure resource/platform logs -> Log Analytics -> Sentinel

SolarWinds:
  Continues alongside Sentinel; it does not replace Sentinel.

Post-deploy gate:
  [ ] LAW reachable/functional
  [ ] Sentinel enabled
  [ ] Azure Activity Logs connected
  [ ] required diagnostics policy assigned
  [ ] alert routing validated
  [ ] evidence captured in HCP/ADO

===============================================================================
4. CONNECTIVITY FOUNDATION - alz-connectivity
===============================================================================

4.1 Hub VNet
------------
Target:
  platform-cus-prod-hub-vnet

Create:
  - resource group
  - VNet
  - required subnets
  - NSGs where appropriate
  - route tables
  - peering contracts
  - Private DNS infrastructure outputs

Required subnet intent:
  - GatewaySubnet
  - Palo Alto management
  - Palo Alto trust
  - Palo Alto untrust
  - Palo Alto HA/auxiliary interface if final vendor design requires it
  - Cloudflare connector subnet
  - DNS/domain-controller subnet (per approved design)
  - DNS Resolver inbound/outbound subnets if Azure Private DNS Resolver is used
  - Bastion subnet if approved
  - private-endpoint/shared-service subnet(s) only where architecture requires

CIDRs MUST come from approved IPAM; never encode sample ranges as production
defaults.

4.2 Routing standards
---------------------
  - no direct spoke-to-spoke peering
  - all spoke-originated internet/on-prem/cross-spoke traffic routes to the hub
  - Palo Alto is the centralized inspection point
  - external apps use Cloudflare for public ingress
  - Cloudflare changes public ingress; it does NOT bypass Palo Alto inspection
    from connector to Azure origin

===============================================================================
5. PALO ALTO VM-SERIES ENTERPRISE PATTERN - alz-connectivity
===============================================================================

ARCHITECTURE SOURCE OF TRUTH
----------------------------
The target design requires:
  - Palo Alto NGFW HA pair
  - NOT Azure Firewall
  - internal load balancer for traffic distribution/failover
  - all north/south + east/west inspected
  - Panorama remains central firewall policy/routing/NAT management
  - Palo Alto logs must reach Sentinel through Panorama/syslog path

TERRAFORM DEPLOYMENT  [DECISION 2026 - Network Architect]
--------------------------------------------------------
DECIDED: Compeer builds the VM-Series appliance with a CUSTOM composition using
the Marketplace *image* (azurerm_marketplace_agreement + source_image_reference
+ plan), NOT the Marketplace solution template and NOT the vendor
PaloAltoNetworks/swfw-modules registry module.

Rationale: the custom pattern expresses Compeer's exact requirement set
(2 firewalls, Trust ILB + a second Sunstream ILB, additional dataplane NICs for
Sunstream, private-only edge, HCP-driven bootstrap) directly, instead of
composing the vendor module and then bolting on the deltas.

Implemented by: patterns/terraform-azurerm-compeer-palo-alto-hub
  - azurerm_linux_virtual_machine (for_each) + network-interface + load-balancer
    modules
  - azurerm_marketplace_agreement for the image licence
  - storage-account + azurerm_storage_share(_directory/_file) for bootstrap
  - custom_data bootstrap: azure-file-share OR custom-data mode

Do NOT reintroduce the swfw-modules vendor module or the archived
terraform-azurerm-vmseries-modules.

5.1 Programmatically accept Azure Marketplace terms
---------------------------------------------------
Terraform:
  azurerm_marketplace_agreement

Conceptual resource:

resource "azurerm_marketplace_agreement" "palo_alto" {
  publisher = var.palo_alto_marketplace.publisher
  offer     = var.palo_alto_marketplace.offer
  plan      = var.palo_alto_marketplace.plan
}

This removes the requirement for a human to accept Marketplace legal terms
during normal deployment.

If agreement already exists:
  IMPORT / reconcile it; do not create competing ownership.

5.2 Bootstrap storage
---------------------
Terraform should create/manage:
  - storage account
  - file share
  - Palo Alto bootstrap directory structure
  - init-cfg.txt or approved bootstrap files
  - secure storage networking as supported by the chosen bootstrap pattern

Use the Palo Alto bootstrap module where it meets requirements.

NEVER commit:
  - auth codes
  - Panorama/API credentials
  - bootstrap secrets

Secret delivery:
  HCP sensitive variables and/or approved Key Vault pattern.

5.3 Deploy firewall pair
------------------------
Target:
  platform-cus-prod-fw-01
  platform-cus-prod-fw-02

Use (per the 2026 decision above - custom composition, Marketplace image):
  module "palo_alto" {
    source = "../../patterns/terraform-azurerm-compeer-palo-alto-hub"
    # virtual_machines = { fw1 = {...}, fw2 = {...} }  -> azurerm_linux_virtual_machine
    # network_interfaces / load_balancers as map(object)
    # marketplace_agreement.enabled = true            -> image licence only
    ...
  }

Required characteristics:
  - two firewalls
  - zone separation where supported/approved
  - management interface
  - trust interface
  - untrust interface
  - fourth interface only according to the final Palo Alto reference design
  - IP forwarding on dataplane NICs
  - managed boot diagnostics/logging where supported
  - approved marketplace image/SKU/version
  - pinned vendor module version

DO NOT assume:
  - "VM-300" maps to a particular Azure VM size
  - BYOL vs bundle license
  - the fourth NIC purpose
These require Network/Palo Alto owner confirmation before apply.

5.4 Load balancing
------------------
Target at minimum:
  Trust ILB + HA ports

Optional/architecture-dependent:
  - untrust/public LB
  - partner-side ILB/LB
  - additional frontend/backend pools

The architecture explicitly requires the internal LB in front of the firewall
pair. Keep LB rules compatible with the Palo Alto active/active/HA-port design.

DO NOT use a generic TCP/22 health probe as a default.
Confirm the approved Palo Alto health-probe endpoint/port with Network
Engineering and expose it as a variable.

5.5 Route tables
----------------
Create UDRs so required spoke traffic uses the Trust ILB frontend / approved
virtual appliance next hop.

Validate:
  [ ] internet egress
  [ ] on-prem path
  [ ] spoke-to-spoke path
  [ ] partner path
  [ ] route symmetry
  [ ] no accidental direct internet path
  [ ] no bypass of firewall for workloads

5.6 What Terraform owns vs Panorama
-----------------------------------
Terraform owns:
  - marketplace agreement
  - Azure VM-Series infrastructure
  - NICs
  - bootstrap storage/artifacts
  - Azure load balancers
  - public/private IP resources where approved
  - UDRs / Azure route associations
  - monitoring plumbing around Azure resources

Panorama is authoritative for Phase 1:
  - device registration
  - template stacks/templates
  - device groups
  - PAN-OS interface/zone configuration
  - security rules
  - NAT/SNAT
  - dynamic routing/BGP inside PAN-OS
  - operational firewall policy
  - log forwarding profiles

Terraform + panos provider is a Phase 2 option ONLY after Network Engineering
accepts Terraform as authoritative for those PAN-OS objects.

5.7 Palo Alto observability gate
--------------------------------
Required before production:
  Palo Alto -> Panorama/syslog/CEF -> Log Analytics/Sentinel

This is NOT optional.
Validate:
  [ ] traffic logs
  [ ] threat logs
  [ ] system/config logs as approved
  [ ] ingestion health
  [ ] alerts on broken forwarding path

===============================================================================
6. HYBRID CONNECTIVITY - alz-connectivity
===============================================================================

6.1 ExpressRoute
----------------
Documented target:
  - new dedicated circuit
  - 2 Gbps
  - Standard (non-Local)
  - Chicago Equinix CH3 primary
  - CH1 under evaluation for metro resiliency
  - legacy 5 Gbps circuit remains with legacy LZ

Terraform where provider ordering permits:
  - azurerm_express_route_circuit
  - peering configuration if owned by Compeer
  - ExpressRoute gateway
  - gateway connection

External/manual dependency:
  - carrier/provider order
  - Equinix cross-connect
  - service key handoff
  - external activation

Do not model "carrier completed" as a Terraform-owned resource.

6.2 VPN backup
--------------
Documented:
  Site-to-site VPN is backup for the new LZ.

Terraform:
  - VPN gateway
  - public IP(s)
  - local network gateway(s)
  - IPsec connections
  - BGP configuration where approved

Secrets:
  VPN PSKs in HCP sensitive variable or approved secret store, never source code.

Validate:
  [ ] ER primary
  [ ] VPN backup
  [ ] route preference
  [ ] failover
  [ ] return-path symmetry through Palo Alto

===============================================================================
7. DOMAIN CONTROLLERS + HYBRID DNS ENTERPRISE PATTERN - alz-identity/connectivity
===============================================================================

DOCUMENTED REQUIREMENTS
-----------------------
The architecture explicitly states:
  - identity is Tier 0
  - domain controllers remain hub-hosted
  - domain controllers and DNS are centralized in the hub
  - all private DNS is hosted centrally in the hub
  - hybrid DNS forwarding is bidirectional
  - Azure must resolve on-prem names
  - on-prem must resolve Azure private names

IMPORTANT OWNERSHIP NOTE
------------------------
The document is clear on network location but less explicit on final Azure
subscription/resource-group ownership of the DC compute.

Before implementation confirm:
  [ ] DC VM subscription ownership: connectivity vs identity platform boundary
  [ ] dedicated subnet
  [ ] AD Site/Subnet mapping
  [ ] static IPs
  [ ] existing domain / replication source
  [ ] approved OS image
  [ ] patching path
  [ ] backup/recovery model
  [ ] monitoring/Sentinel/SolarWinds requirements
  [ ] promotion ownership/tool

Do NOT invent cross-subscription VM/NIC topology to satisfy both "identity
subscription" and "hub-hosted". Use one approved network/ownership pattern.

ENTERPRISE RECOMMENDATION
-------------------------
Terraform owns the Azure VM infrastructure.
AD DS promotion/configuration remains outside Terraform state.

7.1 Terraform-managed DC infrastructure
---------------------------------------
Deploy at least two DC VMs for intra-region resilience, with architecture-team
approval for exact count and zones.

Terraform owns:
  - NICs
  - static private IPs
  - Windows VMs
  - OS/data disks as required
  - Availability Zone placement where supported
  - managed identity where applicable
  - VM diagnostics / AMA association
  - backup enrollment/policy
  - NSG association
  - resource locks if approved

DO NOT put domain-admin passwords into Terraform state.

Conceptual VM pattern:

resource "azurerm_network_interface" "dc" {
  for_each = var.domain_controllers

  name                = each.value.nic_name
  location            = var.location
  resource_group_name = var.identity_resource_group_name

  ip_configuration {
    name                          = "primary"
    subnet_id                     = var.dc_subnet_id
    private_ip_address_allocation = "Static"
    private_ip_address            = each.value.private_ip
  }
}

resource "azurerm_windows_virtual_machine" "dc" {
  for_each = var.domain_controllers

  name                = each.value.name
  location            = var.location
  resource_group_name = var.identity_resource_group_name
  size                = each.value.vm_size
  zone                = each.value.zone

  network_interface_ids = [
    azurerm_network_interface.dc[each.key].id
  ]

  # Local bootstrap credentials must come from an approved secret mechanism.
  # Do not hard-code them in this file.
}

7.2 DC promotion / AD configuration
-----------------------------------
NOT Terraform-owned by default.

Preferred tooling:
  - Ansible
  - PowerShell DSC
  - approved Windows configuration-management pipeline

Sequence:
  1. Terraform creates both Windows VMs.
  2. Wait for platform health/WinRM or approved management connectivity.
  3. Configuration tool installs AD DS/DNS roles as required.
  4. Join/promote first/second DC according to AD team's procedure.
  5. Create/validate AD Sites and Services subnet mappings.
  6. Configure DNS forwarders/conditional forwarders.
  7. Validate replication:
       repadmin /replsummary
       dcdiag
  8. Validate SYSVOL/NETLOGON.
  9. Validate time/NTP hierarchy.
 10. Register monitoring/backup.
 11. Capture evidence.

Secrets for promotion:
  - retrieve at runtime from approved vault
  - never output them
  - never pass them through normal Terraform variables

7.3 NSG / firewall requirements
-------------------------------
The exact AD port matrix must be approved by AD/Security.
Do not use a broad "allow VirtualNetwork" rule as the target standard.

At minimum consider:
  DNS 53 TCP/UDP
  Kerberos 88 TCP/UDP
  RPC 135 TCP
  LDAP 389 TCP/UDP
  LDAPS 636 TCP
  SMB 445 TCP
  Global Catalog 3268/3269 TCP
  NTP 123 UDP
  dynamic RPC range per Compeer Windows standard
  management ports only from approved management sources

Palo Alto policy must also permit the required hub/spoke/on-prem AD flows.

7.4 Azure Private DNS
---------------------
Terraform owns:
  - private DNS zones
  - VNet links
  - private endpoint zone groups where appropriate

Use a map(object(...)) catalogue rather than one resource block per hard-coded
service.

Only create zones actually needed by platform/workloads.
Do not create every known Azure privatelink zone preemptively.

7.5 Hybrid DNS forwarding
-------------------------
Required outcome:
  Azure workload -> hub DNS/DC -> on-prem zones
  On-prem DNS -> Azure private DNS resolution path

Preferred Azure-native pattern where approved:
  Azure Private DNS Resolver
    - inbound endpoint
    - outbound endpoint
    - forwarding ruleset
    - VNet links

If the AD DNS servers remain the forwarding control point:
  Terraform creates the Azure network/resolver infrastructure;
  Ansible/PowerShell/DSC configures Windows conditional forwarders.

Do NOT create dual authoritative forwarding logic in both DNS Resolver and AD
DNS without a deliberate design.

7.6 VNet DNS cutover sequence
-----------------------------
Do not point the hub/spokes to new DC IPs before DC promotion/replication and DNS
health are validated.

Safe sequence:
  1. Deploy DC VMs.
  2. Promote/configure.
  3. Validate DNS/AD health.
  4. Update hub VNet DNS servers.
  5. Update spoke VNet DNS servers.
  6. Restart/re-DHCP clients where Azure requires DNS setting refresh.
  7. Validate forward and reverse resolution.
  8. Validate private endpoint names.
  9. Validate on-prem -> Azure and Azure -> on-prem.

===============================================================================
8. CLOUDFLARE TUNNEL ENTERPRISE PATTERN - alz-connectivity
===============================================================================

DOCUMENTED REQUIREMENTS
-----------------------
  - Cloudflare Tunnel is the standard public ingress path for external-apps-mg
  - no inbound public IP/open hub-firewall port is required for standard
    external-app publication
  - connector VMs are centralized in hub / connectivity subscription
  - connector VMs are platform-owned
  - connectors establish outbound-only encrypted connections to Cloudflare edge
  - application teams consume shared connectors
  - internal-apps and regulated-apps are NOT published through Cloudflare Tunnel
  - connector-to-origin traffic still passes the hub firewall inspection model

8.1 Ownership split
-------------------
Terraform/Azure ownership:
  - connector subnet
  - connector NICs/VMs
  - zones/availability placement
  - managed identity
  - monitoring
  - route/NSG association
  - optional image/extension/bootstrap mechanism

Terraform/Cloudflare provider ownership IF Cloudflare team approves:
  - tunnel
  - tunnel configuration/ingress
  - DNS record
  - Access application/policies
  - selected Zero Trust configuration

Cloudflare operational ownership:
  - WAF tuning
  - bot/DDoS policy
  - account-level settings
  - certificate/edge settings not delegated to platform IaC
  - emergency operations

8.2 Tunnel creation
-------------------
Use the current Cloudflare Terraform provider if API credentials and ownership
are approved.

Conceptual:

resource "cloudflare_zero_trust_tunnel_cloudflared" "external_apps" {
  account_id = var.cloudflare_account_id
  name       = var.cloudflare_tunnel_name
  config_src = "cloudflare"
}

For remotely managed tunnel ingress, manage the tunnel configuration through
the Cloudflare provider rather than maintaining unmanaged YAML on each VM.

8.3 Connector VM pattern
------------------------
Deploy at least two connectors unless Cloudflare architecture owner approves a
different availability model.

Required:
  - no public IP
  - separate zones where supported
  - static or predictable private addressing only if operationally required
  - outbound path through Palo Alto
  - no inbound internet rule
  - least-privilege management path
  - Azure Monitor Agent / approved logging
  - immutable/rebuildable VM pattern preferred
  - connector version pinned/controlled by image or configuration process

Recommended deployment choices:
  A. approved golden image containing cloudflared
  B. configuration-management install (Ansible)
  C. VM extension only if accepted by platform standards

Avoid shelling a long-lived tunnel token directly into source-controlled
Terraform command strings.

8.4 Tunnel credential handling
------------------------------
Preferred:
  - Cloudflare scoped API token in HCP sensitive variable for Terraform provider
  - connector runtime token stored in approved secret store / HCP sensitive
    variable and injected only at bootstrap/runtime

Do not:
  - commit token
  - output token
  - include token in normal diagnostic logs
  - write token to terraform.tfvars

If the chosen Cloudflare Terraform resource returns/generates sensitive tunnel
material, treat the HCP state as sensitive and restrict state access.

8.5 Ingress configuration
-------------------------
For each external app:
  hostname -> private origin

Origin should normally be:
  - private internal load balancer
  - private application ingress
  - private App Gateway frontend
  - other approved private origin

Not standard:
  - public Azure origin
  - direct inbound public IP in the hub

Tunnel config MUST include a terminal catch-all/404 rule.

8.6 DNS / Zero Trust
--------------------
Terraform where approved:
  - Cloudflare DNS CNAME/record to tunnel
  - Zero Trust Access application
  - access policy
  - groups/service-token rules where needed

WAF/DDoS/bot rules:
  manage as code only if Cloudflare/security teams assign Terraform ownership.

8.7 Azure routing/firewall rules
--------------------------------
Critical point:
Cloudflare edge -> outbound tunnel connection -> hub connector -> Palo Alto ->
private external-app origin.

Therefore validate:
  [ ] connector egress to Cloudflare edge
  [ ] DNS/NTP/package/update egress as required
  [ ] connector-to-origin route through Palo Alto
  [ ] Palo Alto allow rule from connector zone to origin zone
  [ ] return route symmetry
  [ ] no direct connector-to-spoke bypass
  [ ] no inbound internet NAT/public rule for standard publication

8.8 Cloudflare logging
----------------------
Architecture status:
  Cloudflare edge logs are RECOMMENDED, not currently mandatory.

Phase 1:
  - monitor connector VM health in Azure
  - monitor tunnel health in Cloudflare
  - alert on connector/tunnel degradation

Phase 2:
  evaluate Cloudflare Logpush -> approved ingestion path -> Sentinel.

===============================================================================
9. SHARED SERVICES / PRIVATE DNS
===============================================================================

The L3 design includes a dedicated shared-services VNet:
  platform-cus-prod-shared-vnet
peered to the hub.

Do not omit this from the implementation plan.

Use it for platform-adjacent shared services only where architecture/ownership
requires. It is not a dumping ground for unrelated resources.

Private DNS:
  - centralized
  - linked to required VNets
  - explicit zone ownership
  - private endpoint zone-group integration standardized
  - no duplicate zone ownership from workload states

===============================================================================
10. WORKLOAD SPOKE ONBOARDING
===============================================================================

For each workload subscription:
  1. Place under correct <domain>-<env>-mg.
  2. Create workload RG(s) aligned to application/service boundary.
  3. Create spoke VNet and subnets.
  4. Peer to hub (no spoke-to-spoke peering).
  5. Configure DNS to approved hub DNS path.
  6. Link required central Private DNS zones.
  7. Associate UDRs forcing required traffic through Palo Alto.
  8. Apply NSG guardrails.
  9. Deploy private endpoints where supported/required.
 10. Enable diagnostics / Sentinel coverage.
 11. Apply tags/ownership.
 12. Validate policy.

External-apps additional:
  13. Add Cloudflare tunnel ingress mapping.
  14. Add DNS / Access / WAF config where owned as code.
  15. Validate connector -> Palo Alto -> private origin.
  16. Confirm no direct inbound public exposure.

Internal-apps:
  Never publish through Cloudflare Tunnel by default.

Regulated-apps:
  Dormant until governance activation trigger is met; stricter controls apply.

===============================================================================
11. KEY VAULT / SECRETS
===============================================================================

Platform Key Vault:
  - RBAC model
  - public network disabled by default
  - private endpoint
  - soft delete
  - purge protection mandatory

Use for:
  - approved firewall API secrets
  - VPN secrets
  - certificates
  - automation secrets where managed identity is impossible

Do not use Terraform to read a secret merely to pass it into another resource
unless unavoidable; that places the value in state.

===============================================================================
12. BACKUP / PATCH / OPERATIONS
===============================================================================

Central Recovery Services Vault:
  - policy by workload criticality tier
  - not ad hoc per VM

Domain controllers:
  - must be covered by an AD-aware recovery procedure
  - backup does NOT replace AD replication/recovery testing

Cloudflare connector VMs:
  Prefer rebuildability over treating connector VMs as pets.
  Backup only if required by operational policy.

Palo Alto:
  Treat appliance configuration as rebuildable from vendor image/bootstrap +
  Panorama where possible.
  Do not rely on VM backup as the firewall configuration system of record.

Update/patch management:
  central platform capability; exact tooling must follow Compeer standard.

===============================================================================
13. POLICY + SECURITY PRODUCTION GATES
===============================================================================

Before any production authorization:
  [ ] approved PR
  [ ] Terraform fmt/validate/TFLint
  [ ] security/IaC scan
  [ ] secret scan
  [ ] HCP authoritative plan
  [ ] policy result reviewed
  [ ] no unexplained destroy/replace
  [ ] owner/tags valid
  [ ] network path validated
  [ ] DNS validated
  [ ] Log Analytics/Sentinel coverage validated
  [ ] Palo Alto telemetry reaches Sentinel
  [ ] backup/recovery evidence
  [ ] exception records attached where applicable
  [ ] rollback/recovery notes captured

===============================================================================
14. END-TO-END BUILD ORDER
===============================================================================

WAVE 0 - CONTROL PLANE
  0.1 Create/confirm ALZ repo(s).
  0.2 Seed validation YAML.
  0.3 Create HCP ALZ project.
  0.4 Create platform workspaces + main branch + working directories.
  0.5 Attach approved variable sets / agent pools.
  0.6 Validate identity/federation.

WAVE 1 - GOVERNANCE
  1.1 Create MG hierarchy.
  1.2 Associate platform subscriptions.
  1.3 Apply baseline RBAC.
  1.4 Assign baseline policy in Audit/DoNotEnforce.

WAVE 2 - MANAGEMENT / OBSERVABILITY
  2.1 Deploy Log Analytics.
  2.2 Enable Sentinel.
  2.3 Enable Defender plans.
  2.4 Deploy action groups / DCRs / central diagnostics.
  2.5 Deploy Recovery Services Vault.
  2.6 Deploy platform Key Vault + private endpoint.

WAVE 3 - HUB NETWORK FOUNDATION
  3.1 Create hub VNet.
  3.2 Create approved hub subnets.
  3.3 Create NSGs/base routing.
  3.4 Create Private DNS/Resolver infrastructure as approved.

WAVE 4 - PALO ALTO
  4.1 Programmatically accept Marketplace agreement.
  4.2 Create bootstrap storage/file-share/files.
  4.3 Deploy VM-Series pair with current Palo Alto vendor module.
  4.4 Deploy Trust ILB/HA ports and required additional LBs.
  4.5 Associate NICs/backend pools.
  4.6 Configure UDR next hops.
  4.7 Network team onboards devices to Panorama.
  4.8 Network team configures PAN-OS zones/routing/NAT/security policy.
  4.9 Build/validate Panorama/syslog -> Sentinel log path.
  4.10 Prove routing symmetry and failover.

WAVE 5 - HYBRID CONNECTIVITY
  5.1 Order/provision ER external service dependency.
  5.2 Deploy ER gateway/configuration.
  5.3 Complete provider cross-connect.
  5.4 Validate ER.
  5.5 Deploy VPN backup.
  5.6 Validate failover and route preference.

WAVE 6 - DOMAIN CONTROLLERS / DNS
  6.1 Deploy DC subnet/NSG.
  6.2 Deploy two DC VMs with static IPs.
  6.3 Register monitoring/backup.
  6.4 AD team promotes/configures via Ansible/DSC/PowerShell.
  6.5 Configure AD Sites/Subnets and DNS conditional forwarding.
  6.6 Validate AD replication and DC health.
  6.7 Update hub/spoke VNet DNS only after health checks.
  6.8 Validate hybrid DNS in both directions.
  6.9 Validate Azure Private DNS/private endpoints.

WAVE 7 - CLOUDFLARE
  7.1 Create/confirm Cloudflare account-level prerequisites.
  7.2 Create Tunnel with Cloudflare Terraform provider if approved.
  7.3 Deploy 2+ connector VMs in hub with no public IP.
  7.4 Install/configure cloudflared via approved immutable/config-management path.
  7.5 Configure tunnel ingress.
  7.6 Configure Cloudflare DNS.
  7.7 Configure Access/WAF controls where Terraform-owned.
  7.8 Configure Palo Alto connector-to-origin policy.
  7.9 Validate outbound-only tunnel, HA, failure, and no public inbound bypass.

WAVE 8 - SHARED SERVICES / SPOKES
  8.1 Deploy/peer shared-services VNet if active.
  8.2 Deploy internal/external workload spokes.
  8.3 UDR -> Palo Alto.
  8.4 Private DNS links.
  8.5 Private endpoints.
  8.6 NSGs.
  8.7 diagnostics.

WAVE 9 - PRODUCTION READINESS
  9.1 Validate Policy.
  9.2 Validate Sentinel.
  9.3 Validate Palo Alto logging.
  9.4 Validate DNS/AD.
  9.5 Validate ER/VPN.
  9.6 Validate Cloudflare path.
  9.7 Validate backups.
  9.8 Capture evidence.
  9.9 Promote selected policies to Deny after approval.

===============================================================================
15. EXPLICIT ITEMS THAT REMAIN OUTSIDE TERRAFORM UNLESS OWNERS APPROVE
===============================================================================

Palo Alto / Panorama:
  - operational NGFW policy
  - NAT/SNAT
  - PAN-OS zone/interface policy
  - device-group/template-stack lifecycle
  - vendor licensing/registration steps not supported by approved automation

Domain Controllers:
  - domain promotion
  - AD DS role configuration
  - AD Sites and Services
  - GPOs
  - domain admin secret handling
  - authoritative AD recovery operations

Cloudflare:
  - account-wide edge/WAF operational policy unless delegated to IaC
  - emergency edge operations
  - any existing Cloudflare resources not imported into Terraform ownership

ExpressRoute:
  - carrier/Equinix physical provisioning and activation

===============================================================================
16. MODULE DESIGN STANDARD FOR THIS IMPLEMENTATION
===============================================================================

Use narrow/lifecycle-aligned modules:

  hub-network
    -> VNet/subnets/base NSG outputs

  palo-alto-vmseries-pattern
    -> CUSTOM composition (Marketplace image, NOT vendor module / NOT solution
       template): azurerm_linux_virtual_machine + NICs + Azure LBs, marketplace
       agreement, bootstrap storage/files, Azure route integration
    -> NOT Panorama operational policy

  expressroute
    -> Azure ER circuit/gateway/connection objects

  vpn-gateway
    -> VPN gateway/LNG/connections

  domain-controller-vm
    -> Windows VM infrastructure only
    -> NOT AD promotion/GPO

  private-dns
    -> zones/links

  dns-resolver
    -> resolver endpoints/rulesets

  cloudflare-connector
    -> Azure connector VM infrastructure

  cloudflare-publication
    -> tunnel/ingress/DNS/Access policy where Cloudflare Terraform ownership is
       approved

  diagnostics
    -> diagnostics/DCR/monitoring attachments

  private-endpoint
    -> PEP + DNS attachment

Avoid:
  - giant "landing-zone" module
  - hidden subscription/subnet lookups
  - dynamically discovering critical platform dependencies by name
  - timestamp-driven tags that cause perpetual drift
  - storing domain/firewall/tunnel secrets in tfvars
  - local Terraform production apply

===============================================================================
17. MINIMUM TYPED INPUT MODEL
===============================================================================

variable "location" {
  type    = string
  default = "centralus"
}

variable "hub_address_space" {
  type = list(string)
}

variable "hub_subnets" {
  type = map(object({
    name             = string
    address_prefixes = list(string)
    nsg_key          = optional(string)
    route_table_key  = optional(string)
  }))
}

variable "palo_alto_marketplace" {
  type = object({
    publisher = string
    offer     = string
    plan      = string
    version   = string
  })
}

variable "domain_controllers" {
  type = map(object({
    name       = string
    nic_name   = string
    private_ip = string
    vm_size    = string
    zone       = optional(string)
  }))
}

variable "cloudflare_apps" {
  type = map(object({
    hostname          = string
    origin_service    = string
    access_group_ids  = optional(list(string), [])
    enable_access     = optional(bool, true)
  }))
  default = {}
}

variable "tags" {
  type = map(string)
}

===============================================================================
18. FINAL IMPLEMENTATION OUTCOME
===============================================================================

When the waves above are complete, the platform should have:
  - CAF-aligned management groups/subscriptions
  - centralized Central US hub
  - Palo Alto HA inspection layer
  - ExpressRoute primary + VPN backup
  - hub-hosted AD/DNS integration
  - centralized Private DNS
  - Cloudflare Tunnel as external-app public ingress
  - no standard direct public ingress to external-app origins
  - workload spokes forced through Palo Alto
  - mandatory Log Analytics/Sentinel coverage
  - Defender + Azure Policy guardrails
  - centralized backup
  - HCP Terraform governed execution and evidence
  - Azure DevOps validation/evidence pipeline

This file is the sequencing/implementation guide. Each section should be
implemented in its own Terraform root/module rather than copied into one state.
*/
