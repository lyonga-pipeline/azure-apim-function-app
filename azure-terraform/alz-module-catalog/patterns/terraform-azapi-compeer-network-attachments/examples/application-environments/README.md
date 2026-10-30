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
| `platform-network-peering-dev` | claims, loans |
| `platform-network-peering-perf` | loans |

Use [prod](prod.tfvars.example), [dev](dev.tfvars.example) and [perf](perf.tfvars.example) as the committed configuration examples for **separate copies** of the [generic root template](../../../../implementations/platform-lz/templates/network-attachments/README.md). Do not share one backend/root and swap these files at deployment time. These disabled examples contain placeholder UUIDs, reservations and approval values; they do not create the application VNets or assume all apps need every environment.

Generic-v3 producer owners publish matching `context.environment` and `attachment_kind="workload"`, actual VNet metadata and DNS intent using the [output-only adapter](../../producer/README.md). The existing blueprint-v2 path remains valid with its own naming context. Acceptance of a custom environment by the peering pattern does not change the separate VNet producer's naming/governance standards; that producer must also support and approve the label.

The root rejects cross-environment producers rather than silently filtering them out. Adding a missing environment later is an approved VNet deployment, output publication, scoped RBAC and inventory PR. Removing an attachment is an explicit reviewed teardown, not an automatic consequence of changing a shared environment matrix.
