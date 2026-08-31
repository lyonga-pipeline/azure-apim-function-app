# terraform-azurerm-compeer-palo-alto-hub

**Pattern module.** Deploys the Azure side of a Palo Alto VM-Series firewall hub
**entirely in Terraform** - no Marketplace *solution template*. Terraform owns
every VM, NIC, load balancer, public IP, and the bootstrap artifacts, so the
deployment matches Compeer's requirements (2 firewalls, an extra internal load
balancer + NICs for Sunstream, private-only edge) instead of the fixed
Marketplace shape.

## Marketplace vs. image-based - the distinction

| | Marketplace solution template | This pattern (image-based) |
|---|---|---|
| What deploys | Microsoft-authored template: 2 VMs + 1 internal LB, fixed | Whatever you declare in tfvars |
| VM plan/agreement | Accepted by the template | `azurerm_marketplace_agreement` (still required - it is the **image licence**, not the template) |
| Extra NICs / 2nd LB (Sunstream) | Not possible | Add map entries |
| Custom routing, identities, tags | Bolt-ons afterward | Native |

Set `marketplace_agreement.enabled = true` **once per subscription** to accept
the `paloaltonetworks / vmseries-flex / <plan>` image agreement. That is not
"using Marketplace" in the solution-template sense.

## What it composes

| Concern | Resource / module | Notes |
|---|---|---|
| Bootstrap storage | `storage-account` module + `azurerm_storage_share` | `public_network_access_enabled = false` by default |
| Bootstrap layout | `azurerm_storage_share_directory` / `_file` | `config` / `content` / `license` / `software` + `init-cfg.txt` |
| Public IPs | `public-ip` module | mgmt + untrust only; pin their RG in the private-only allow-list |
| NICs | `network-interface` module | `ip_forwarding_enabled = true`; 3 per firewall + any Sunstream NICs |
| Load balancers | `load-balancer` module | `trust` ILB + `sunstream` ILB (just another map key) |
| Firewall VMs | `azurerm_linux_virtual_machine` (for_each) | `source_image_reference` + `plan`; system-assigned identity |
| PAN official module | `PaloAltoNetworks/swfw-modules//modules/vmseries` `3.5.1` | Alternative via `vendor_vmseries` (mutually exclusive with `virtual_machines`) |

## Bootstrap (`virtual_machines[*].bootstrap`)

| `mode` | Needs | `custom_data` becomes | State impact |
|---|---|---|---|
| `none` (default) | - | unset | - |
| `azure-file-share` | `storage_account_name`, `storage_account_key` | `storage-account=...\naccess-key=...\nfile-share=...\nshare-directory=...` (base64) | **the key is in Terraform state** |
| `custom-data` | `custom_data` or `init_cfg_content` | your text (base64) | none |

`bootstrap_share_layout` lays down the PAN-OS folder structure and can upload an
`init-cfg.txt` / `bootstrap.xml` from a local path or inline `content`.

For a key-free flow, use `mode = "custom-data"` with a PAN-OS 10+ `init-cfg.txt`
(`type=dhcp-client`, `plugin-op-commands`, `dgname`, `tplname`, `vm-auth-key`)
and let the firewall pull config from Panorama / Strata Cloud Manager.

## Sunstream

Sunstream needs a second internal load balancer and additional dataplane
interfaces. Both are plain map entries - no module change: add
`fwN_sunstream` keys to `network_interfaces`, a `sunstream` key to
`load_balancers`, and the extra NIC keys to each firewall's
`network_interface_keys`.

## Lifecycle contract

| Change | Effect |
|---|---|
| Add a `virtual_machines` / `network_interfaces` / `load_balancers` key | Creates just that instance (stable `for_each` keys). |
| `virtual_machines[*].size` | In-place resize (VM restart). |
| `virtual_machines[*].bootstrap`, `custom_data`, `source_image_reference` | **Replace** the VM (`custom_data` is ForceNew). Plan a firewall-by-firewall window. |
| `network_interface_keys` order/content | Replace the VM. |
| `bootstrap_share_layout` files | In-place upload; does not touch VMs. |

## State exposure

`bootstrap.storage_account_key` (file-share mode) and `admin_password` are stored
in Terraform state. Prefer `custom-data` mode + SSH keys. Outputs:
`virtual_machine_ids`, `virtual_machine_identity_principal_ids`,
`network_interface_ids`, `load_balancer_ids`, `public_ip_ids`,
`bootstrap_storage_account_id`, `bootstrap_storage_share_ids`,
`marketplace_agreement_id`.

## Migration

Additive only. New: `virtual_machines[*].bootstrap`,
`virtual_machines[*].identity`, `bootstrap_share_layout`, the
`azurerm_storage_share_directory` / `_file` resources, and the `local` provider.
`azurerm_storage_share` switched from the deprecated `storage_account_name` to
`storage_account_id`.

Panorama / Strata Cloud Manager policy onboarding stays a separate operational
contract. Keep the workspace disabled until firewall licensing, image plan
acceptance, the bootstrap process, and routing ownership are approved.

## Tests

`terraform test` - 2 firewalls / 2 LBs / 6 NICs, both bootstrap modes rendered,
the four bootstrap directories, and the file-share-without-key rejection.
