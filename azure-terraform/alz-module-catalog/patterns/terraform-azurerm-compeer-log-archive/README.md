# Regulatory Log Archive

**PHASE2 NEW:** v5 OBS-05. Dedicated audit-capable resilient storage, approved WORM policy, LAW export, private read endpoint and optional retention deletion.

## Ownership And Defaults

Reuse source LAW, approved subnet and central DNS zone. Audit may use the same LAW only if this export excludes `StorageBlobLogs` and `AzureMetrics`; otherwise supply a different existing audit LAW to prevent a feedback loop. `archive=null` creates nothing. This pattern creates a dedicated monitoring destination, not workload data storage or a new LAW.

## Inputs And Outputs

| Input | Default | Purpose |
| --- | --- | --- |
| `resource_group_name` | `Required` | Existing monitoring archive RG. |
| `location / tags` | `centralus / {}` | Match source LAW region; owner/classification metadata. |
| `archive` | `null` | Name, existing LAW/audit LAW/subnet/DNS, approved retention, resilient replication, selected tables, export readiness and optional delete/lock approvals. |


The typed [variables.tf](variables.tf) defines every nested setting and guard; [outputs.tf](outputs.tf) exposes resource IDs by caller-stable key. Required context inputs do not create resources. Optional collections are opt-in. Use an existing approved resource group; this pattern does not own its lifecycle.

Use the independent [workspace root](../../implementations/platform-lz/workspaces/platform-log-archive) and its `terraform.tfvars.example` for inert defaults. `approved-pilot.tfvars.example` demonstrates explicit reference values, not production approvals. Replace all synthetic values and review ownership before enabling any entry.

```hcl
module "phase2" {
  source = "../../patterns/terraform-azurerm-compeer-log-archive"
  resource_group_name = "platform-cus-prod-archive-rg"
  archive = null # Opt in with approved-pilot.tfvars.example only after review.
  # Supply required context and explicitly approved capability maps from tfvars.
  # In deployment roots, promote to a reviewed pinned registry version.
}
```

## Operational Contract

FCA retention is a GRC input, not a default. Selected-network AzureServices ingress needs policy approval; no anonymous access or shared keys. Unlocked mode is a pilot, not immutable enforcement. Locking is irreversible. Export is same-region/new-data only, with possible retries/duplicates; append blobs are not cool-tiered. Prove end-to-end export and deletion protection.

Blob versioning is explicitly enabled for account-level WORM. That account-level capability is a creation-time decision, not a retrofit for an existing account; adopt an existing archive only after validating its capabilities and a no-replacement plan. Blob read/write/delete logs and account metrics are configured separately. Omit `delete_after_days` to create no lifecycle policy; a configured deletion age must exceed retention. Add export-failure alerting through the observability pattern using the source LAW's native `ExportFailed` metric.

References: [version-level WORM prerequisites](https://learn.microsoft.com/en-us/azure/storage/blobs/immutable-version-level-worm-policies), [LAW export restrictions](https://learn.microsoft.com/en-us/azure/azure-monitor/logs/logs-data-export).

[Phase 2 readiness and acceptance](../../implementations/phase2/RUNBOOKS.md) distinguishes mock coverage from live acceptance. No ARM management locks are added. Terraform >=1.11.4 is required; provider constraints are in [terraform.tf](terraform.tf).

## Validation

```sh
terraform init -backend=false
terraform validate
terraform test
```

Mocks test enabled/disabled composition and guards without Azure/HCP credentials. They do not prove live permissions, service quotas, network/data delivery or business compliance. Run real speculative plans and approved pilot checks before release.
