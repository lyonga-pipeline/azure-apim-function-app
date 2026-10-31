# Phase 2 Readiness and Live Acceptance

**PHASE2 NEW:** operational completion criteria for workbook activities that cannot be proved by a Terraform plan. Attach named owner, approval/change reference, UTC timestamp, scope, expected result and actual evidence to every check. Do not run failover, password rotation, patching or policy remediation without a change window.

Use the canonical workspace owners and adoption sequence in [ENGINEERING-HANDOFF.md](ENGINEERING-HANDOFF.md). `implementations/phase2` is a delivery index, not a deployable workspace. Keep existing resource ownership and publish required pattern patch releases before enabling new sections.

Network attachments follow [PEERING-STANDARD.md](../platform-lz/PEERING-STANDARD.md):
environment/hub-boundary grouping is the target, current adapters remain single-pair,
and existing identity half-peerings are a recorded legacy exception. Require approved
Git/IPAM inventory, exact producer cross-checks, environment-specific plan/apply OIDC
and reviewed aggregate RBAC. Enforce the shared-hub gate across environment/exception
and relevant core runs, and serialize mutations inside each run. Keep inline hub
routes and spoke UDRs with their existing owners; do not duplicate either VNets or
route ownership. Include Panorama changes and partial-apply/retirement recovery in
the live change record. A plan success or Connected status alone is not acceptance.

## Carried Dependencies: 1.2-1.7

- **SolarWinds (1.2):** monitoring owner selects agents and supported OSs. Network owner approves source/destination/ports and Panorama rules. Test each new VM from Central US; confirm inventory, alerts and SOC visibility in SolarWinds, not merely an installed extension.
- **SCCM (1.3):** identify current patch authority, management/distribution points and firewall path. Prove inventory, content download and an approved pilot patch/reboot. Keep coverage until Update Manager is accepted. Never leave DCs/firewalls without a patch owner.
- **ExpressRoute (1.5/1.6):** confirm carrier-provisioned circuit, approved private peering/BGP ASN/prefixes, zonal gateway SKU/region and connected gateway connection. Inspect learned/effective routes both ways, DNS and application probes, NVA forwarding and symmetric return. Azure connection creation is not on-prem BGP configuration.
- **Equinix (1.7):** carrier/network team configures NCUS-CUS fabric routing. Prove each direction and route isolation. The design prohibits direct Azure hub peering; do not add it to resolve connectivity.

## Monitoring and SOC: 2.1-2.9, 3.5, 3.7-3.9

- Create/reuse DCE/DCRs in their existing owner before AMA association. For private ingestion verify regional DCE/DCR destinations, AMPLS membership and DNS; manage/import the VM's single `configurationAccessEndpoint` association or confirm its external owner. Assign the declared UAMI to each VM, then deploy AMA. Collect approved Windows Event/Security sources and Linux Syslog; avoid overlapping Sentinel connector/DCR ingestion. MDE/Defender for Endpoint onboarding is separate from AMA.
- Verify real Heartbeat/Event/SecurityEvent/Syslog records and latency. Change Tracking needs a supported extension and inventory-specific DCR, not just a generic heartbeat DCR. Query ConfigurationChange/ConfigurationData after an approved test.
- Test every alert query against actual tables and permission context. Baseline triggers: connector service/tunnel down >30 minutes; LAW ingestion/export failure; playbook failure; reviewed >25% ingestion deviation; ExpressRoute and firewall health. VM heartbeat alone does not establish cloudflared service health. Send a controlled alert through the action group and confirm escalation/acknowledgement.
- ITSM owner supplies the incident endpoint, Entra app/object/audience permissions, schema/severity mapping, deduplication, retry and closure behavior. New `receivers.webhook.*.aad_auth` supports authenticated delivery; it does not implement an ITSM API. Azure Monitor must reach the endpoint; a private-only URL is not sufficient.
- **Cribl/Palo (2.5):** confirm funding, tenant/API ownership and named support. Panorama -> Cribl -> Sentinel test events must arrive parsed with correct timestamps/fields. Validate outage buffering/recovery, access and detection rules. Do not claim a LAW connector config proves ingestion.
- **Defender (2.7):** choose plan/subplan/extensions per actual workload and pricing approval. Keep either policy/DINE remediation or direct pricing as the single subscription owner. Verify real Microsoft.Security/pricings Standard/subplan values and effective coverage; a compliance audit assignment alone does not enable existing resources.
- **Archive (2.3):** approve retention/legal scope and supported export tables, test real export plus failure/throttling alerts, verify private reader DNS/RBAC and trusted-service ingress. Export covers newly ingested data, not historical backfill. Prove delete/overwrite denial only after an explicitly approved immutability lock. Document legal-hold and retention-change procedures.
- **GRC evidence (3.5):** use the read-only collector, export active exemptions and record initiative definition versions/parameters/assignment scopes. Link results to approved control applicability and compensating controls. Azure compliance percentage is not FCA/GLBA/SOX certification.
- **Network visibility (3.7):** use VNet flow logs and Traffic Analytics; Security owns scope, retention and ingestion-cost review. New NSG flow-log creation is no longer supported. Reuse the existing Watcher rather than creating competing per-region instances.
- **Connection Monitor/DDoS (3.8/3.9):** decide SolarWinds overlap before synthetic probes. Install/verify Network Watcher agent and routes. Test approved endpoints and thresholds. DDoS is opt-in after public IP/protection applicability and cost approval; Cloudflare alone does not imply every Azure VNet needs a plan.

## Encryption, Secrets and JIT: 3.1-3.3

CMK must be justified by a security control. Existing key rotation policies and DES auto-rotation are reusable. Use RBAC-only protected/private Key Vaults, appropriate wrap/unwrap permissions, versionless key references where required, recovery/key-availability procedures and service-specific consumer configuration. Test rotation without data loss before production.

Secret rotation is not key rotation. The service-specific handler must validate event source/type and allowed secret, tolerate duplicate/out-of-order events, lock concurrent rotations, generate a new credential without logging it, update the backing service and vault safely, verify consumer success, and roll back or retain alternate credentials on failure. Prefer managed identity over passwords. The new pattern references an existing system topic with SystemAssigned identity, an existing Function and dead-letter container; its readiness flags require real test evidence. Restrict Function identity permissions in the backing service separately. Exercise retry/dead-letter alert/replay and document ownership.

Defender JIT (3.3) is manual: approve eligible VMs/ports/source CIDRs/session duration, verify Defender plan prerequisites and NSG enforcement, then prove access is closed outside an approved request. Do not expose public RDP/SSH or assume JIT configures Palo Alto guest policy.

## External Access and Partners: 4.1-5.3

Network owns reserved hub connector/Partner subnets. Cloudflared VMs are shared hub infrastructure; applications onboard to tunnels/Access, not per-app connector fleets. Confirm egress, supported bootstrap/upgrade, redundancy and tunnel health. Cloudflare owner approves DNS/IdP/auth/API scopes. Keep tokens out of code/tfvars/logs.

Partner routing needs the 0.19 architecture approval. Keep gateway transit off; Network/Panorama owners implement approved on-prem static routes and SNAT exceptions (Compeer-to-Compeer must not be NATed). Capture forward/return packet paths before approving multiple HA-port ILBs/shared backends; existing Terraform shape alone is not proof of symmetry.

## External Identity: 6.1-6.4

Use existing CSP `ent-platform-identity-ext-sub`, dedicated external identity RG/VNet and two DCs in separate zones. Central attachment owns both peerings; identity root does not write the hub. Validate firewall hairpin, AD ports, DNS and restricted management source rules before promotion. Add approved inspection routes for more-specific remote prefixes, not only 0.0.0.0/0.

Set the identity root's optional `central_attachment` metadata and apply its foundation first to publish `network_attachment_contract` v3.0.0. Merge the matching `platform`/`prod` entry into the complete `platform-network-peering-prod` inventory; do not replace the existing map or infer membership automatically from outputs. Private DNS intent must match exactly, including `{}` when none is required. The older `central_attachment_inputs` output is compatibility metadata, not the batch consumer contract. See the [identity root handoff](../platform-lz/workspaces/platform-identity-external/README.md#central-attachment-handoff).

AD team must decide whether compeer.ext is a new forest, existing forest extension and/or trusted forest, then approve DNS forwarding/sites/subnets/time/privileged credentials. For existing domains, additional-DC promotion can perform the join; separate JsonADDomainExtension is not a prerequisite. For a new forest, only DC01 creates it; DC02 joins by additional-DC promotion after DC01 is healthy. Promotion stays outside Terraform state. Install AD DS/DNS with management tools, then controlled promotion/reboot. Validate `dcdiag`, `repadmin /replsummary`, SYSVOL/NETLOGON, DNS and intended sites. Do not assume whole-forest object replication across every domain partition.

Use dedicated external identity RSV and approved backup retention. Confirm policy enrolment, successful backups and an isolated AD-aware restore drill. VM backup is not the whole AD forest recovery procedure. Resolve vault network isolation/endpoint requirements before deployment.

## Resilience, Services and Governance: 7.1-10.4

- **ER Metro (7.1):** carrier approves CH1/CH3 or equivalent genuinely diverse MSEE/provider paths. Test loss of each path in a change window and confirm advertised routes/application recovery.
- **Golden images (8.1):** private gallery definitions are infrastructure only. Compute owner owns Packer/Image Builder, patching, vulnerability scan, software licensing, trusted boot, image test/approval, version publication, rollback and retirement. Use tested image version IDs in production, not `latest`.
- **Update Manager (8.2):** decide SCCM vs Azure authority. VM owner first configures supported OS/agent, AutomaticByPlatform and customer-managed schedule readiness. Pilot non-DC hosts; stagger DCs and verify AD health before patching the second controller.
- **Vending (9.1):** existing CSP onboarding remains authoritative. Only governance can enable vending after billing scope/CSP permissions, request approval, MG placement, baseline RBAC/policy and rollback are designed.
- **FinOps (9.2):** approve billing currency/amount, actual/forecast recipients, anomaly emails, supported billing offer and storage export access. Budgets notify; they do not cap spend or power off resources. Reuse existing budgets by extending/importing their owner, never duplicate across states.
- **HCP (9.3):** health assessments need supported execution mode, entitlement and working credentials. Before adoption, inspect/import workspace settings and preserve agent pool, sharing, execution and approved apply behavior; remove overlapping property ownership from `tfe_workspace`. Exclude Panorama-owned guest state from Terraform expectations.
- **Sandbox (10.1-10.4):** governance moves four existing subscriptions only after descendant-policy impact review. Deploy separate sandbox roots with explicit expiration_date, reviewed budget and central attachment. Expiry is a tag/approval workflow, not automatic deletion. Keep required inspection/audit and prod isolation. Scheduled expiry review must initiate an approved teardown or renewal.

Record unresolved decision owners rather than filling approval fields with placeholders. Phase 3 holds remain in [ON-HOLD.md](ON-HOLD.md).

## Component List Additions

- **GOV-01:** extend management groups through the existing governance owner. Compare the full live hierarchy before edits; retain deployed dormant branches. Verify inherited policy and privileged access before placing subscriptions.
- **IAM-05:** use exact HCP/ADO issuer, audience and subject claims. Separate production/non-production and plan/apply principals. A plan identity may require approved data-plane read permissions beyond Reader; scope these explicitly. Prove an actual short-lived federated login without client secrets and reject a token from another workspace/run phase.
- **SEC-04:** SOC approves detection versions, telemetry prerequisites and automation scope. Exercise a safe synthetic event through analytics, incident creation, playbook and ticket routing; verify false-positive tuning and failure alerts. Existing Sentinel Fusion deprecation is tracked in REVIEW.md, not silently migrated.
- **SEC-12:** reuse central Bastion and its approved Standard/Static PIP. Verify the reserved Bastion subnet/required NSG rules, narrow public-IP policy exception, least-privilege operator access and BastionAuditLogs in the central LAW. Do not deploy per-application Bastion hosts or relax public RDP/SSH rules.
