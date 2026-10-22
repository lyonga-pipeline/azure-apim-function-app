# Step 11 Coverage And Architecture

Reviewed against the actual v13 design, v4 component workbook, refined resource
placement sheet and NET-22 / 204115 acceptance criteria. See
[DESIGN-ALIGNMENT.md](DESIGN-ALIGNMENT.md) for source rows, phase holds and conflicts.
All seven Step 11 functions have code implementations and local
tests. That is not client deployment, enterprise certification or ticket sign-off.

| Step | Component | Implementation | Evidence |
| --- | --- | --- | --- |
| 11.1 | WKL-01 spoke blueprint | Reusable spoke-landing-zone pattern; public-contract reads in each environment root | Real module composition, contract/subscription guards, IPAM overlap and network/security negative tests |
| 11.2 | NET-23 production spoke | workload-internal-apps-prod root directly pinning its blueprint release | Enabled-root mock apply, production profile, disabled placeholders and address-migration tests |
| 11.3 | NET-24 non-production spoke | workload-internal-apps-nonprod root independently pinning the same blueprint | Enabled-root mock apply, non-production profile, same security controls and address-migration tests |
| 11.4 | NET-22 bidirectional peering | Platform-owned network-peering adapter calling the hub-spoke-peering pattern; blueprint publishes intent only | Cross-state contract consumption, both directions, gateway approval, subscription/tenant/DNS guards; optional live Connected checks |
| 11.5 | NET-29 private endpoint pattern | Canonical private-endpoint module composed by the Key Vault/storage parents | Correct target, subnet, subresource and central zone-group wiring; no standalone duplicate PE state |
| 11.6 | WKL-07 workload Key Vault | Dedicated workload-key-vault pattern by default; approved secretless workload opt-out | Private-only RBAC vault, purge protection, required central diagnostics and scoped service roles when enabled; see CAPABILITIES.md |
| 11.7 | IAM-06 managed identity | Canonical user-assigned-identity module plus parent-owned role assignments | ID/client ID/principal outputs, vault-scoped Secrets User; telemetry/Blob access only when their approved optional parent is enabled |

The seven components do not need seven wrapper modules or seven workspaces.
NET-29 follows the component list's intent: let the parent own its endpoint and
DNS zone group. The generic canonical module remains reusable for other approved
PaaS parent patterns. IAM-06 similarly reuses the existing identity module and
keeps service access with the resource owner; no blanket Owner/Contributor role
or implicit deployment-principal secret access is added.

## Peering Decision

Selected Compeer model: central attachment, both directions from a separate
platform-owned workspace. See [ATTACHMENT.md](ATTACHMENT.md) for deployment,
permissions and the required existing-state handoff.

```text
Per-application/environment provisioning state and independently pinned root
  -> reads public platform contracts
  -> versioned spoke blueprint (not live shared/)
       -> private Key Vault + endpoint + scoped identity access
       -> publishes versioned attachment_contract

Platform network attachment state, per approved application/environment
  -> consumes spoke contract and approved hub outputs
  -> hub-spoke-peering reusable pattern: BOTH directions
  -> existing-zone VNet links

Application state
  -> consumes spoke IDs/contracts
  -> deploys mixed-workload compute and application-specific services
```

Both environment roots can follow `main` without following live blueprint changes.
See [ISOLATION.md](ISOLATION.md) for promotion, workspace settings and migration.

The spoke has no hub provider or peering/link module calls. The deprecated
manage_hub_attachment input must remain false; true fails with migration
guidance. The central owner holds the approved pair-scoped permissions, not
the spoke pipeline. Both directions and required links have one state owner.
Central ownership does not require one global state or one all-spoke identity.
Private endpoint creation still requires the approved central-zone join rights;
it does not authorize broad management of the hub or DNS subscription.

## Enterprise Controls And Boundaries

- Existing management/connectivity/governance public output contracts only; no full state or
  sensitive-output fallback. The peering core itself needs no HCP provider/token.
- Separate workload environments/subscriptions, tags, identities and access groups;
  budgets are removed from this Phase 1 package and remain a governance Phase 2 concern.
  Production resilience/optional alerting profiles retain the same
  private/RBAC/security baseline in non-production.
- Approved IPAM ranges, NSG/UDR on each subnet, explicit hub/NVA egress and DNS
  forwarding dependency. Gateway flags default off until network approval.
- Dedicated workload vault and identity; parent-owned private endpoint/DNS zone
  group, central diagnostics and exact-resource ownership metadata.
- Central LAW/Sentinel/Defender/flow-log policies remain with existing platform
  owners. No duplicate hub appliances, bastion, security instance or DNS zones.
- Shared action groups are referenced from management's public output or approved
  IDs. A new application group/component requires explicit creation; an existing
  approved application/environment telemetry component can be referenced without
  owning its configuration or grants. See [REUSE.md](REUSE.md).
- No workload resource locks. Mixed compute, ingress, database lifecycle and
  service-specific backups remain application-specific, as requested.
- OBS-09 Application Insights and OBS-04 workload alerts are off by default;
  activation examples are commented out. Private-only telemetry needs the
  centrally approved AMPLS path; that path is not created here. Phase holds do
  not waive mandatory R3.4 production observability requirements.

The HCP adapter retains legacy input behavior unless contract mode is enabled.
Existing spoke-owned attachments require a separately reviewed state handoff,
not resource deletion or an automatic move. Removed old inline peering moves
do not transfer ownership between separate state files. Keep actual Azure names.

## Remaining Acceptance Gates

Committed examples stay disabled with placeholders. Supply approved IPAM,
subscriptions and groups (plus approved recipients if activating alerts),
then validate in an isolated or
approved staging environment. NET-22 acceptance requires both Connected
peerings plus representative shared-service access, effective routes/firewall
symmetry and hybrid DNS, not just two resource IDs. NET-29/IAM-06 acceptance
requires actual endpoint approval, private resolution and managed-identity
secret access. Step 12 additionally covers pilot deployment, resilience/failover,
PIM and operational/governance sign-off. See TESTING.md and the opt-in integration
runbook; none of these live/manual gates is marked complete by local tests.
