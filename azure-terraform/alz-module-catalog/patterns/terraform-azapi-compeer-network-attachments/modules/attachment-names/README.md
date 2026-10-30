# Network Attachment Names

Provider-free helper that follows the Compeer naming convention for **existing VNet identities**. It accepts `vnet_peerings={key={local_vnet,remote_vnet}}` and `private_dns_link_vnets=[existing_vnet_name]`. Outputs preserve the parent module's formulas: `<local>-to-<remote>` and `<vnet>-link`, lowercased, with Azure's 80-character limit checked.

No environment, region, appcode, domain or platform component is needed: these child-resource names depend only on the already-approved VNet names. This avoids weakening the broader naming module's approved environment catalogue or inventing workload metadata for a platform VNet. The parent module's existing interface/names are unchanged; the parity test compares these outputs with that interface.

This helper lives inside the network-attachments pattern, so the pattern publishes and versions it as one unit and the published Compeer naming module is not involved. Its formulas intentionally match the naming module's `vnet_peering_names` and `private_dns_link_names`; the monorepo-only test in `tests/` compares the two so they cannot drift. Long names require explicit approved peering-name overrides at the attachment composition layer; they are not silently truncated or renamed here.
