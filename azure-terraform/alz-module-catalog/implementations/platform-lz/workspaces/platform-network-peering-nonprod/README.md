# Platform Network Peering Non-Production

PHASE 2: one platform-owned state manages both peering directions and approved DNS VNet links for all declared non-production VNets on the approved hub. Production remains independent. This replaces the **unapplied** np1/np2/np3 example roots, not an existing deployed state.

## Configure

- Edit the committed [terraform.tfvars](terraform.tfvars): complete np1/np2/np3 examples include public producers, CIDRs, forwarding/transit settings, DNS zones/link names and explicit reciprocal peering names.
- Keep only VNet instances that actually exist. Add apps/environments as reviewed entries with stable keys. `allowed_environments` authorizes actual producer labels; it cannot include `prod` or the grouping label `nonprod`. Every entry's actual environment must match its producer. No producer is relabelled.
- Naming: `peer-<attached-vnet-name>-to-hub` and `peer-hub-to-<attached-vnet-name>`. Both directions are always created. Preserve existing names on import; renaming a deployed peering can replace it. No identity peering is added here.
- Replace all documentation IDs/CIDRs/workspaces and change/IPAM references. Publish/pin the verified HCP pattern and naming dependency; configure public-output access, scoped OIDC/RBAC and the protected shared-hub gate. Set adoption attestations true only when those controls exist, then enable.

## Deployment Boundary

HCP workspace: `platform-network-peering-nonprod`; working directory: this root. Use an independent approved release pin, main-branch trigger path and non-production plan/apply identities. Environments in this state share its release, permissions, plan/recovery scope and approval lifecycle. Split only if those requirements diverge.

The populated inventory is inert while `enabled=false` on this UNAPPLIED root. **Never disable a live state to pause runs**: that plans destruction. Stop/lock runs operationally. Do not switch this backend between environments with runtime tfvars. The hub gate also covers production, core connectivity and legacy hub writers.

VNets/routes/zones/private endpoints/Palo Alto retain their existing owners. Identity/single-pair ownership is unchanged. If any old np workspace was applied outside this repository, freeze both owners and explicitly transfer only its approved child bindings; do not merely rename its working directory or create duplicates.

See the [batch pattern](../../../../patterns/terraform-azapi-compeer-network-attachments/README.md), [operating runbook](../../network-attachments/README.md) and [standard](../../PEERING-STANDARD.md).

## Verification

`terraform init -backend=false`, `terraform validate` and `terraform test` exercise inert defaults, adoption/allowlist guards and the actual committed inventory using mocked APIs. Actual authorization, Connected/DNS status and inspected/forbidden traffic still require a live approved pilot.
