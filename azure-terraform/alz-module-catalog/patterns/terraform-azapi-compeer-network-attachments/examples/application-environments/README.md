# Different Environment Counts

There is **no mandatory four-environment matrix** and no `environment_count` input. Each independent root lists only VNet instances that actually exist and are approved for that boundary.

| Application | Actual Environments | Count |
| --- | --- | --- |
| accounts | prod | 1 |
| claims | dev, prod | 2 |
| loans | dev, perf, prod | 3 |

| Independent Attachment Root | Inventory |
| --- | --- |
| `platform-network-peering-prod` | accounts, claims, loans |
| `platform-network-peering-nonprod` | claims_dev, loans_dev, loans_perf; allowlist dev/perf |

The recommended two roots have complete committed inventories: [prod](../../../../implementations/platform-lz/workspaces/platform-network-peering-prod/terraform.tfvars) and [nonprod](../../../../implementations/platform-lz/workspaces/platform-network-peering-nonprod/terraform.tfvars). Approve dev/perf in the latter's allowlist when used and declare each entry's actual environment; generic-v3 entries require it explicitly in a grouped state.

The older [prod](prod.tfvars.example), [dev](dev.tfvars.example) and [perf](perf.tfvars.example) files remain **optional finer-grained boundary examples**, for separate copies of the [generic root template](../../../../implementations/platform-lz/templates/network-attachments/README.md) only when separate lifecycle/permissions justify them. Do not run these as subsets against the consolidated backend: omitted keys would propose deletion. All examples are disabled placeholders and do not create application VNets.

Generic-v3 producer owners publish matching `context.environment` and `attachment_kind="workload"`, actual VNet metadata and DNS intent using the [output-only adapter](../../producer/README.md). The existing blueprint-v2 path remains valid with its own naming context. Acceptance of a custom environment by the peering pattern does not change the separate VNet producer's naming/governance standards; that producer must also support and approve the label.

The root rejects producers outside its allowlist or differing from the entry's actual environment, rather than silently filtering them out. Adding a missing environment later is an approved VNet deployment, output publication, scoped RBAC and inventory PR. Removing an attachment is an explicit reviewed teardown, not an automatic consequence of changing a shared environment matrix.
