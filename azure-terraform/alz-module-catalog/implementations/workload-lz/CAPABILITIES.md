# Capability Controls And Ownership

2026-10-20 amendment: the user approved a vault opt-out for workloads that need no
vault, while retaining required audit logging for enabled vault/storage resources.
This is a documented variation of Step 11's dedicated-vault-by-default baseline,
not a claim that the original component list required an opt-out.

Set these values inside `spoke` in either copied workload root's tfvars/HCP object.
The blueprint exposes the same objects directly as module inputs.

| Capability | Off | Create / Reuse |
| --- | --- | --- |
| Key Vault | `key_vault.enabled=false` | Default true creates a dedicated private RBAC/purge-protected vault; platform vault reuse is intentionally not provided |
| Blob storage | Empty map or `storage_accounts.data.enabled=false` | Enabled entries create only needed private, keyless stores, endpoints and scoped optional UAMI access |
| Application Insights | `monitoring.enabled=false` | Enabled plus `create_application_insights=true`, OR `existing_application_insights={id,workspace_id}` |
| Failed-request alert | `monitoring.alerts_enabled=false` | New by default when alerts enabled; reuse with `create_failed_requests_alert=false` and `existing_failed_requests_alert={id,application_insights_id,action_group_ids}` |
| Action group | `operations.create_action_group=false` | Reuse selected `platform_action_group_keys` or explicit `action_group_ids`; create with true + approved emails only for a new alert consumer |
| Audit diagnostic creation | `diagnostics.enabled=false` | Allowed only with existing coverage for every enabled target; default true creates missing declared targets, references override creation per target |
| Existing VM backup enrollment | `backup=null` or `backup.enabled=false` | True plus real existing VM, vault and approved policy IDs in the workload subscription |

Reuse does not mutate the external resource. The adapter does not select a new
platform action route for an existing alert; its declared existing action groups
are used. No component/alert reuse decision creates an otherwise empty operations RG.

Diagnostic reference keys are `key_vault`, `storage.<logical-key>.account` and
`storage.<logical-key>.blob`. Each value declares `id`, `workspace_id`,
`log_categories` and `metric_categories`. Required coverage:
- Vault: AuditEvent + AllMetrics.
- Storage root: AllMetrics, no unsupported allLogs group.
- Blob child: StorageRead, StorageWrite, StorageDelete + Transaction.

Checks reject unknown/stale keys, wrong target IDs, wrong central LAW, missing
categories, create-and-reuse conflicts and alerts scoped to another component.
Terraform checks declared contracts, not live external configuration. The live
verifier checks actual IDs/configuration and duplicates. DINE is not a synchronous
replacement for required settings; no blanket policy exemption is created here.
The existing v1 flat diagnostic registration fields remain vault-only for
compatibility. Use diagnostic_ownership.targets for resource-specific storage
profiles; never apply the vault AuditEvent profile to Blob resources.

Central LAW/hub/DNS/Sentinel/Defender/flow-log ownership is unchanged. The central
attachment state receives only DNS links actually needed by enabled services.
Upgrade the copied central attachment adapter before publishing a secretless
contract with a null vault-zone ID; do not use an older consumer that assumes a vault.
The UAMI, network security, inspection, naming and tags stay mandatory. Parent
security controls cannot be weakened through an optional capability flag.
Budgets, locks, compute and subscription vending remain excluded.

## Examples And Migration

The runnable reference suite is at
`../../patterns/terraform-azurerm-compeer-spoke-landing-zone/examples` relative to
this workload-lz directory; its README covers all variants and approvals.

Existing addresses are preserved through moved blocks for the counted vault and
its counted diagnostic module. Default behavior remains enabled vault and managed
audit coverage. Before switching **already deployed** resources to off/reuse,
review destruction and arrange explicit state transfer without Azure deletion.
A false flag is not a pause, import, soft-delete bypass or ownership transfer.
