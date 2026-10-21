# Platform-Owned Network Attachment

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

Instantiate separate platform-owned states/identities as appropriate; do not
interpret "central" as one global state or grant for all subscriptions.
Serialize changes to a shared hub across workspaces.

Deployment sequence, exact input examples, permissions and the mandatory
existing-state handoff are in [ATTACHMENT.md](../../../workload-lz/ATTACHMENT.md).
Do not apply a spoke plan that destroys an existing connection.
