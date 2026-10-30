# Platform-Owned Network Attachment Single Pair Adapter

The [peering standard](../../PEERING-STANDARD.md), revised 2026-10-28, selects
one attachment workspace per environment and hub/network security boundary as
the default, with multiple approved spokes and dedicated-workspace exceptions.
The approved Git inventory authorizes membership; producer outputs are cross-checks.
This root remains a **single-pair compatibility/example implementation**. It does
not yet accept an attachments map or implement the four environment batch roots.
Do not instantiate a workspace per application as the new default, or move a live
state merely by changing this root's source/working directory.

This root owns both peering directions and required DNS VNet links for one
approved application/environment connection. The spoke blueprint publishes the
versioned attachment_contract but does not name or create those resources.
The central adapter generates attachment names with the pinned Compeer naming
module. New spokes publish version 2.0.0; version 1.0.0 is supported for migration.
Central peering_names/private_dns_link_names overrides preserve approved custom
names where required; never accept an unexpected rename/replacement plan.

The committed example remains disabled. Replace the actual HCP producer names,
set approved subscription/tenant/DNS inputs and scoped credentials, and enable
use_spoke_attachment_contract=true. Read only public outputs. The requested
gateway-transit setting must be explicitly approved with matching flags here.

Use boundary-specific platform plan/apply identities, not an identity per app or
one global network identity. The environment model aggregates permissions only
on approved VNets/zones; grants at a shared hub still reach its other peerings.
Ordinary Terraform cannot dynamically select AzureRM provider aliases per map
entry. The new [AzAPI batch implementation](../../../../patterns/terraform-azapi-compeer-network-attachments/README.md)
uses full parent IDs and provider-process serialization instead; its four new
roots still require the protected external shared-hub gate and live adoption.
Hub/spoke VNets and routes remain with their existing owners. The split-owner
identity attachment is a recorded legacy exception until a reviewed handoff.

Deployment sequence, exact input examples, permissions and the mandatory
existing-state handoff are in [ATTACHMENT.md](../../../workload-lz/ATTACHMENT.md).
Do not apply a spoke plan that destroys an existing connection.
