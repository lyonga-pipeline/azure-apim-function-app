# Platform Network Peering Production

PHASE 2: one platform-owned production-only attachment state. Each declared VNet gets both peering directions and approved DNS VNet links, using one AzAPI provider across subscriptions. The root fixes `allowed_environments=["prod"]`; non-production producers are rejected.

## Configure

The committed [terraform.tfvars](terraform.tfvars) includes hub/producer references, CIDRs, IPAM/change references, forwarding/transit intent, exact private DNS zones/link names and both explicit names:

- Spoke to hub: `peer-workload-cus-prod-int-orders-vnet-to-hub`.
- Hub to spoke: `peer-hub-to-workload-cus-prod-int-orders-vnet`.

Each entry always creates both halves. Naming follows Compeer's identity/hub convention, but existing identity peerings are NOT added or migrated. Preserve live names on an approved import; renaming a peering can replace it.

Replace all documentation values, retain only existing VNets and use stable keys. DNS intent must match producer outputs exactly. Gateway transit stays off unless approved and the actual hub gateway is ready. Routes/firewall inspection remain separate owner changes.

This UNAPPLIED root stays disabled with its inventory populated. Before enabling, publish/pin the verified HCP pattern and naming dependency, configure public-output access, scoped OIDC/RBAC and the protected shared-hub gate, and record actual adoption approvals. **Never disable a live state to pause it**: stop/lock runs instead.

## Isolation And Ownership

HCP workspace: `platform-network-peering-prod`; working directory: this root. Keep an independent release pin, main-branch trigger path, production plan/apply identities and production approvals. Non-production lives in `platform-network-peering-nonprod`, not runtime-selected tfvars against this backend.

Hub/attached VNets, routes, zones, private endpoints and Palo Alto retain their existing owners. The shared-hub gate covers both roots and core/legacy writers. Hub-scoped RBAC still reaches other child peerings: production state isolation is not physical hub isolation.

See the [batch pattern](../../../../patterns/terraform-azapi-compeer-network-attachments/README.md), [operating runbook](../../network-attachments/README.md) and [standard](../../PEERING-STANDARD.md). Do not repoint an applied legacy backend without a reviewed child-resource handoff.

## Verification

`terraform init -backend=false`, `terraform validate` and `terraform test` include mock application of the actual tfvars inventory and both explicit names. Actual OIDC/RBAC, Connected/DNS status and inspected/forbidden traffic require a live approved pilot.
