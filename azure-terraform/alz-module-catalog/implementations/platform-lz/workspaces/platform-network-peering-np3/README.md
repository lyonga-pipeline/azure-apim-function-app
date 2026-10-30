# Platform Network Peering NP3

One independently deployed **np3 + approved hub boundary** state. Multiple stable-key attachments may span workload subscriptions; one AzAPI provider addresses their full ARM IDs.

See the [batch pattern](../../../../patterns/terraform-azapi-compeer-network-attachments/README.md) for inputs, the production-shaped multi-subscription example, OIDC/RBAC, testing and migration. See the [network standard](../../PEERING-STANDARD.md) for ownership and acceptance.

This root is disabled and unapplied. Confirm the environment mapping, replace placeholders, publish/pin an approved pattern release and configure the common hub gate before adoption. HCP working directory is this root; trigger changes to this inventory/root and its selected release only. Do not use runtime tfvars to turn it into another environment. Use the same protected hub gate as the other environment and core hub workspaces.

Never toggle `enabled=false` on a live state to pause deployments: it proposes removal. Lock/stop runs operationally instead. Existing identity split ownership remains unchanged until an approved handoff.
