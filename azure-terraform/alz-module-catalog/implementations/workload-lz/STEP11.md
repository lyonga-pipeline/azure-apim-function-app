# Step 11 Coverage And Architecture

Reviewed against the supplied component-list screenshot and NET-22 / 204115
acceptance criteria. All seven functions have code implementations and local
tests. That is not client deployment, enterprise certification or ticket sign-off.

| Step | Component | Implementation | Evidence |
| --- | --- | --- | --- |
| 11.1 | WKL-01 spoke blueprint | spoke-landing-zone pattern plus shared public-contract adapter | Real module composition, contract/subscription guards, IPAM overlap and network/security negative tests |
| 11.2 | NET-23 production spoke | workload-internal-apps-prod root calling the shared blueprint | Enabled-root mock apply, production profile and disabled-placeholder tests |
| 11.3 | NET-24 non-production spoke | workload-internal-apps-nonprod root calling the same blueprint | Enabled-root mock apply, non-production profile, same security controls |
| 11.4 | NET-22 bidirectional peering | hub-spoke-peering pure Azure pattern, called by the blueprint or HCP adapter | Both directions, gateway pairing, names, subscription/tenant/DNS guards; optional live Connected checks |
| 11.5 | NET-29 private endpoint pattern | Canonical private-endpoint module composed by the Key Vault/storage parents | Correct target, subnet, subresource and central zone-group wiring; no standalone duplicate PE state |
| 11.6 | WKL-07 workload Key Vault | Separate workload-key-vault pattern, mandatory inside blueprint | Private-only RBAC vault, purge protection, central diagnostics and scoped service roles |
| 11.7 | IAM-06 managed identity | Canonical user-assigned-identity module plus parent-owned role assignments | ID/client ID/principal outputs, vault-scoped Secrets User, component-scoped telemetry publishing; optional explicit Blob access |

The seven components do not need seven wrapper modules or seven workspaces.
NET-29 follows the component list's intent: let the parent own its endpoint and
DNS zone group. The generic canonical module remains reusable for other approved
PaaS parent patterns. IAM-06 similarly reuses the existing identity module and
keeps service access with the resource owner; no blanket Owner/Contributor role
or implicit deployment-principal secret access is added.

## Peering Decision

Recommended default for these platform-provisioned spokes:

```text
Platform provisioning state
  -> shared public-contract adapter
  -> spoke blueprint
       -> hub-spoke-peering reusable Azure pattern: BOTH directions
       -> parent-owned existing-zone VNet links
       -> private Key Vault + endpoint + scoped identity access

Application state
  -> consumes spoke IDs/contracts
  -> deploys mixed-workload compute and application-specific services
```

This separates code concerns without unnecessarily splitting one platform
provisioning transaction across states. The platform run identity, not an
application-team credential, has narrowly scoped hub/zone permissions. The
peering ticket produces a reusable capability and validation evidence even
though the blueprint calls it automatically.

For independently owned workload provisioning, use manage_hub_attachment=false
and a separately approved central attachment root, which owns both directions
and the corresponding DNS links. That root can consume the published attachment
contract/public outputs. Never split the two directions between competing states
or apply the old attachment root to a spoke whose blueprint already owns them.
Private endpoint creation still requires the approved central-zone join rights;
it does not authorize broad management of the hub or DNS subscription.

## Enterprise Controls And Boundaries

- Existing management/connectivity output contracts only; no full state or
  sensitive-output fallback. The peering core itself needs no HCP provider/token.
- Separate workload environments/subscriptions, tags, identities, access groups
  and approved budgets; production resilience/alerting profiles with the same
  private/RBAC/security baseline in non-production.
- Approved IPAM ranges, NSG/UDR on each subnet, explicit hub/NVA egress and DNS
  forwarding dependency. Gateway flags default off until network approval.
- Dedicated workload vault and identity; parent-owned private endpoint/DNS zone
  group, central diagnostics and exact-resource ownership metadata.
- Central LAW/Sentinel/Defender/flow-log policies remain with existing platform
  owners. No duplicate hub appliances, bastion, security instance or DNS zones.
- No workload resource locks. Mixed compute, ingress, database lifecycle and
  service-specific backups remain application-specific, as requested.
- Application Insights public HTTPS ingestion/query is Entra-authenticated and
  explicit in tfvars. Private-only telemetry needs the centrally approved AMPLS
  path; this code does not pretend that path is already established.

The legacy HCP network-peering adapter retains Azure names by default and has
moved blocks for its internal module refactor. The new spoke also has moved
blocks for its earlier inline peering addresses. Existing deployed consumers
must review a real plan and confirm moves, not replacements, before apply.
These declarations do not transfer ownership between separate state files.

## Remaining Acceptance Gates

Committed examples stay disabled with placeholders. Supply approved IPAM,
subscriptions, groups, budgets and recipients, then validate in an isolated or
approved staging environment. NET-22 acceptance requires both Connected
peerings plus representative shared-service access, effective routes/firewall
symmetry and hybrid DNS, not just two resource IDs. NET-29/IAM-06 acceptance
requires actual endpoint approval, private resolution and managed-identity
secret access. Step 12 additionally covers pilot deployment, resilience/failover,
PIM and operational/governance sign-off. See TESTING.md and the opt-in integration
runbook; none of these live/manual gates is marked complete by local tests.
