# Spoke Landing Zone Blueprint

New-deployment blueprint for WKL-01 / ticket 204092. The production (NET-23 /
204094) and non-production (NET-24 / 204114) workspaces use this same pattern.
It composes the catalog's resource-group, naming, tags, VNet/subnet, NSG, route,
association, peering, DNS-link, identity, diagnostics, monitoring, storage and
budget modules. It does
not copy the identity-specific names or invalid `scope = "identity"` from the
supplied reference; naming scope is `workload`, and RG outputs are keyed maps.

Step 11.4 uses the separate reusable hub-spoke-peering Azure pattern, rather
than copying its two peering resources into the blueprint. The older
network-peering HCP adapter delegates to the same implementation. See
implementations/workload-lz/STEP11.md for all seven Step 11 capabilities and the
code/state ownership decision. NET-29 and IAM-06 reuse the canonical endpoint
and identity modules through parent-owned composition, not duplicate wrappers.

## What It Creates

- Network, security, application and operations RGs in the workload subscription,
  plus a data RG only when storage is requested, with approved generated
  names and mandatory tags. The shared root persists `created_on` with time_static.
- One VNet and IPAM-supplied IPv4 subnets, addressed by stable logical keys.
  The private_endpoints subnet is mandatory, non-delegated and NSG-enforced.
- An NSG and route table on EVERY subnet. Baseline inbound/outbound denies
  precede Azure's broad default VNet rules. Application subnets allow DNS,
  private-vault HTTPS, load-balancer probes and hub-routed outbound HTTPS.
  Application-specific ports require explicit reviewed rules at priorities
  300-4000. Reserved baseline rules cannot be overwritten.
- Explicit `default_outbound_access_enabled=false` and a default route through
  an approved hub firewall/NVA IP. No public IP, NAT gateway, firewall, bastion,
  VPN, Route Server or other duplicate hub services are created.
- Both reciprocal hub peerings and a link to the EXISTING Key Vault private
  DNS zone, unless the central attachment state owns all three instead.
- A user-assigned workload identity and the separate workload-key-vault pattern
  by default. The identity receives vault-scoped Secrets User, not Officer,
  Administrator, Contributor or Owner.
- Approved Reader/Contributor workload groups. Resource-lock creation and its
  input/output switch have been removed, not merely disabled.
- Workspace-based Application Insights, Entra-only telemetry authentication,
  workload-scoped Monitoring Metrics Publisher, an operational action group (or
  approved existing groups), an application failure alert and a monthly budget
  with 80/100% actual and 100% forecast notifications. The budget amount and real
  recipients are mandatory approved inputs, not invented defaults.
- Optional private Blob accounts, each with its own PE, central zone registration,
  TLS 1.2, no shared keys/public access, versioning and soft deletion. Account
  metrics go on the account; read/write/delete logs go on blobServices/default.
  No allLogs category is applied to the storage-account parent.
- Optional enrollment of explicitly supplied existing VMs into an approved
  existing Recovery Services vault/policy in the workload subscription. It does
  not create empty backup vaults or claim that all workload data is protected.

The vault is in the workload security RG, not the shared platform security
subscription. Application secrets remain scoped to their own workload.

## Production And Non-Production Profiles

| Setting | Production | Non-production |
| --- | --- | --- |
| Subscription, names, identities, vault, access groups, on-call recipients and budget | Separate approved production values | Separate approved non-production values |
| Optional Blob replication | ZRS by default; ZRS/GZRS/RAGZRS required | LRS default; may select ZRS for staging |
| Blob/container soft deletion | 30 days minimum | 7 days default |
| Telemetry sampling | 100% starting setting | 20% starting setting |
| Failure-alert severity / evaluation | Severity 1 / every minute | Severity 3 / every five minutes |
| Failed-request count in a 5-minute window | 5 starting setting | 20 starting setting |
| Key Vault RBAC/private access/purge protection, subnet controls, storage TLS/keyless access, diagnostic destination | Same secure controls | Same secure controls |

Sampling/failure thresholds are tunable starting settings, not a measured SLO
or universally correct production alert. Tune them using actual volume, SDK
sampling configuration and the application's service objectives. Security-log
retention is not reduced in non-production. Central LAW/table retention remains
owned by platform-management; the component uses that same LAW in both profiles.
Storage replication changes may require migration; review plans and never treat
an environment change on an existing state as an in-place promotion.

## Mixed Workload Boundary

This is a common application landing-zone FOUNDATION, not a deployment of every
Azure service. Per the mixed-workload decision, VM/VMSS, App Service/Functions,
AKS, databases, ACR, WAF/ingress and service-specific private endpoints belong
to the consuming application deployment, chosen from the approved catalog.
Applications consume application_services, subnet_ids, key_vault,
workload_identity and context. These are real resources/contracts, not a claim
that the application runtime has already been deployed.

The application team still configures telemetry SDK/agents, attaches/selects
the identity, and obtains approved Application Insights connection metadata.
Entra authentication is mandatory; no instrumentation key or connection string
is published in the public spoke contract. Public HTTPS ingestion/query is the
explicit initial setting, reached through approved hub egress and authenticated
by Entra/RBAC. It is NOT private-only telemetry. Disable either endpoint only
after the centrally owned AMPLS/private DNS path works and set private_link_ready.
That declaration does not create or independently prove AMPLS connectivity.

Recovery is workload-specific: VM backup enrollment requires real VM/vault/policy
IDs, proper backup permissions and region compatibility; approved policies must
meet the production/non-production RPO/RTO. SQL/PaaS backups and restore drills
remain with their workload patterns. Terraform removal stops VM protection and
retains backup data in the supplied roots; it does not purge recovery points.

## Contract And Network Guards

`platform` consumes ONLY public management/connectivity contract 0.1.0 fields:
central LAW ID, hub VNet ID/ranges, existing vault/optional Blob private-zone IDs, DNS IPs, and
an optional DDoS plan ID. Missing/changed contracts fail rather than omitting
security resources. Explicit approved values are supported for isolated tests.

The provider aliases are `azurerm` (workload), `azurerm.connectivity` (hub) and
`azurerm.dns` (actual zone subscription, which can differ from the hub).
The pattern checks all provider subscriptions and the common tenant.

CIDRs are checked for full containment and overlap, including hub and supplied
IPAM reserved/on-prem ranges. This is not a global IPAM allocator: callers must
provide the complete approved reserved-range inventory and a real next-hop IP.
The next hop must be within the hub range. Actual firewall/NVA readiness and
inspection rules are network-team dependencies; Terraform cannot infer them.

Central hybrid DNS is the default. An empty server list requires explicit
`allow_azure_provided_dns=true`. Linking a private zone does not create a DNS
forwarder or make on-prem/custom DNS resolve Azure private names. Validate the
real forwarding path before accepting workload secret consumption.

Gateway transit defaults off. Enable `gateway_transit_enabled` only after the
network team confirms gateway/Route Server/SD-WAN readiness; both required
peering flags are changed together. A configured route/flag is not proof that
on-prem routes are being exchanged.

## Ownership

| Configuration | Owner |
| --- | --- |
| Workload RGs, VNet, subnet NSGs/UDRs, identity, vault and AuditEvent setting | This workload state |
| Application telemetry, alerts/budget, requested Blob accounts/diagnostics and explicit VM backup enrollments | This workload state |
| Both peerings and required vault/Blob-zone VNet links | This state when manage_hub_attachment=true |
| Same attachment resources | Central attachment state when manage_hub_attachment=false |
| Central LAW, Sentinel, platform monitoring | platform-management |
| Approved Defender plans, VNet flow logging and diagnostic safety net | platform-policy |
| Subscriptions, MG placement, privileged groups/PIM | Existing onboarding/authorization owners |

Never manage a peering or zone link from two states. Switching attachment owners
on a deployed spoke is an explicit state handover/import exercise, not a toggle
to apply blindly. External mode publishes attachment_contract but does not claim
that connectivity is live. The existing platform-network-peering root can
consume the flat VNet/RG outputs; configure its DNS provider correctly if the
existing zone lives outside the hub subscription.

The vault diagnostic baseline is AuditEvent + central LAW, compatible with the
category DINE policy. Compliant Terraform settings satisfy DINE independent of
name. For strict Terraform-only correction, register diagnostic_ownership's
exact vault ID with platform-policy; no broad exemption is created here.
This pattern never creates Defender pricing, flow-log resources or competing
management-group policy assignments.

Storage diagnostic_resource_ids/log categories are published per account in
application_services.storage. Register those exact account/Blob targets with
platform-policy when strict Terraform-only correction is required. Do not use
the vault's AuditEvent profile for Blob logs or create a blanket workload-scope
policy exemption. The account has metrics only; the Blob child has the three
supported read/write/delete categories.

The workload roots use AzureRM >=4.81 and storage.data_plane_available=false,
with storage_use_azuread=true. The Blob account/control-plane settings can be
created privately without temporarily enabling public/shared-key access. Do
not add queue_properties/static_website data-plane blocks to this provider path.
Containers, blobs and other actual data need an authorized private-network
runner; the baseline creates no empty data-plane objects. Storage is optional
because allocating an unused account is not an application requirement.

## Deployment

Use implementations/workload-lz/workspaces/workload-internal-apps-prod or
workload-internal-apps-nonprod. Both contain disabled PLACEHOLDERS as requested;
they are not client-ready deployment values. The nonprod root accepts dev,
test, uat or the approved np1/np2/np3 aliases, never prod.

Do not point an existing legacy platform-workload-spoke state at this blueprint.
The resource addresses, mandatory vault and RG layout differ. Existing workloads
require a reviewed migration/state-move plan. The legacy pattern is unchanged.

## Tests

`terraform test` uses mocked Azure providers but REAL catalog modules. It
includes an apply-style composition test and negative cases for overlap,
out-of-VNet subnets, wrong provider subscriptions, contract drift, Internet-wide
inbound rules and bypass routes. Both environment roots test disabled placeholders
and enabled public-contract consumption. The separate vault suite checks its
observed security settings, private access, role scope and input validation.

The integration-tests directory contains a REAL Azure deployment fixture and
run.sh. It is deliberately excluded from automatic mock tests. Read its README
before opting in: it incurs costs, needs an isolated subscription and cannot
prove private DNS or secret access from an unconnected public CI runner.

## Architecture References

- https://learn.microsoft.com/en-us/azure/architecture/networking/guide/private-link-hub-spoke-network
- https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/azure-best-practices/hub-spoke-network-topology
- https://learn.microsoft.com/en-us/azure/key-vault/general/best-practices
- https://learn.microsoft.com/en-us/azure/virtual-network/ip-services/default-outbound-access
