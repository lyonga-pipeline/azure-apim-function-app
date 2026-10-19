# Workload Deployment And Acceptance Gates

The disabled examples are templates, not deployed production/non-production
landing zones. Mock tests are code evidence; they do not close NET-22's live
connectivity criterion or establish licensing, billing or stakeholder approval.
Locks remain deliberately absent. Do not add them as an acceptance prerequisite.

## Before The First Enabled Plan

| Gate | Required evidence / owner |
| --- | --- |
| Subscription | CSP supplies actual IDs; subscription-onboarding owns correct prod/non-prod MG placement and approved access. No subscription is created or moved by the spoke. |
| Platform contracts | Successful management/connectivity/governance applies; actual HCP names and scoped output-read access, or approved explicit inputs including mandatory_tag_keys. Do not turn on full-state sharing for tfe_outputs. |
| NET-01 / IPAM | Approved VNet/subnet ranges plus complete relevant on-prem, reserved and other-spoke inventory. reserved_address_spaces=[] is not evidence of an overlap-free enterprise network; only supplied ranges and the published hub are checked. |
| NET-02 / hub | Actual hub VNet/NVA next hop, exact inspection_address_prefixes, disabled spoke BGP propagation, reciprocal hub routes, firewall/SNAT approval and return-path readiness. DNS zones/providers point to their actual subscription. |
| IAC-07 / access | Approved deployment identity, workload/hub/DNS scope permissions and constrained RBAC-assignment rights; existing authorized runner for private data-plane checks. |
| Operations | Governance owns the subscription baseline budget; confirm CSP support. Optional workload telemetry/alerts are held pending approval. If enabled, require real recipients/SLOs; a spoke budget requires explicit ownership handoff and positive approved amount. R3.4 go-live coverage remains mandatory regardless of phase holds. |
| Reused services | Confirm selected management action-group keys/IDs, enabled status, intended audience and actual test delivery. For existing Application Insights, confirm the real central LAW linkage, application/environment isolation, Entra authentication, SDK ingestion and the owner of its UAMI grant. A supplied ID/workspace declaration or successful mock is not live verification. See REUSE.md. |
| Policy | Approved applicable Defender/diagnostic/flow-log assignments and remediation permissions; platform-policy remains the owner. Read compliance after convergence, not just after assignment creation. |
| Attachment | One state owns both peering directions and required DNS links. Use manage_hub_attachment=false only with an approved central attachment owner. |

The blueprint can create a spoke and then compose its peering pattern in the
same apply. A reusable NET-22 code dependency is not a requirement to deploy a
peering before the NET-23 VNet exists. In external-attachment mode the order is
spoke creation, central attachment, then connectivity validation.

## Read-Only Client Checks

Run these only against an approved deployed application/environment. They do
not run terraform apply, create a fixture, modify routes, or destroy resources.
Use explicit subscriptions; do not rely on the current Azure CLI default.

```bash
export HUB_SUBSCRIPTION_ID='<approved hub subscription UUID>'
export HUB_RESOURCE_GROUP='<actual hub resource group>'
export HUB_VNET_NAME='<actual hub VNet name>'
export SPOKE_SUBSCRIPTION_ID='<approved workload subscription UUID>'
export SPOKE_RESOURCE_GROUP='<actual spoke network resource group>'
export SPOKE_VNET_NAME='<actual spoke VNet name>'

az network vnet peering list --subscription "$HUB_SUBSCRIPTION_ID" \
  --resource-group "$HUB_RESOURCE_GROUP" --vnet-name "$HUB_VNET_NAME" \
  --query '[].{name:name,remote:remoteVirtualNetwork.id,state:peeringState,access:allowVirtualNetworkAccess,forwarded:allowForwardedTraffic,gateway:allowGatewayTransit}' -o json
az network vnet peering list --subscription "$SPOKE_SUBSCRIPTION_ID" \
  --resource-group "$SPOKE_RESOURCE_GROUP" --vnet-name "$SPOKE_VNET_NAME" \
  --query '[].{name:name,remote:remoteVirtualNetwork.id,state:peeringState,access:allowVirtualNetworkAccess,forwarded:allowForwardedTraffic,remoteGateway:useRemoteGateways}' -o json
```

Identify the exact approved hub/spoke pair by its remote VNet ID. Both must show
Connected and the expected flags; an unrelated Connected peering is not proof.
Connected alone does not prove DNS, routing, NVA policy or application access.

From an existing authorized workload-network host, record private DNS resolution
and actual access to an approved private endpoint/service. For example, run
nslookup for the deployed vault FQDN and confirm the returned private address
matches its approved endpoint subnet. A successful public DNS lookup or an
unauthenticated HTTP response is not proof of private secret access. Use the
application's managed identity to read an approved existing test secret and
record success/identity/network metadata only; never log secret values. Do not
write/delete a client secret merely to imitate the isolated fixture probe.

Record effective routes/NSG results from an existing authorized workload NIC,
inspected egress through the actual NVA, required shared-service connectivity,
return-path symmetry and approved hybrid DNS/on-prem paths. If no authorized
workload host exists yet, keep those criteria pending until the pilot workload.

## Evidence Record

| Evidence | Recorded result |
| --- | --- |
| Application, environment, subscription, HCP run/commit, UTC date | Pending |
| Exact reciprocal peering IDs / Connected states | Pending |
| Private DNS, PE connection and managed-identity access | Pending |
| Effective routes, NSGs, NVA/return path and required shared services | Pending |
| Central diagnostic ingestion without duplicate settings | Pending |
| Approved Defender/flow-log compliance after convergence | Pending |
| Operational alert routing, budget support and approved thresholds | Pending |
| Application/platform/network/security stakeholder sign-off | Pending |

The isolated integration-tests fixture remains optional automated Azure evidence
in a separately approved test subscription. It is not a prerequisite to run
these read-only client checks and does not replace production acceptance.
