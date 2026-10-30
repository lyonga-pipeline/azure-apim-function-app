# Network Attachment Names

Provider-free subset of Compeer naming for **existing VNet identities**. It accepts `vnet_peerings={key={local_vnet,remote_vnet}}` and `private_dns_link_vnets=[existing_vnet_name]`. Outputs preserve the parent module's formulas: `<local>-to-<remote>` and `<vnet>-link`, lowercased, with Azure's 80-character limit checked.

No environment, region, appcode, domain or platform component is needed: these child-resource names depend only on the already-approved VNet names. This avoids weakening the broader naming module's approved environment catalogue or inventing workload metadata for a platform VNet. The parent module's existing interface/names are unchanged; parity tests compare these outputs with that interface.

Publish this new submodule as part of an approved naming release before a registry consumer uses it. It is not present merely because an older naming version is installed. Long names require explicit approved peering-name overrides at the attachment composition layer; they are not silently truncated or renamed here.
