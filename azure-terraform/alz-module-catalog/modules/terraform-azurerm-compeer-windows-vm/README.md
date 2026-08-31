# terraform-azurerm-compeer-windows-vm

Lean single Windows VM (`azurerm_windows_virtual_machine`). NICs, managed data
disks, extensions and domain-join are caller-owned and composed by their
dedicated modules (`network-interface`, `windows-vm-domain-join`, ...). This is
the preferred Windows VM resource boundary; `windows-virtual-machine` is the
older composite variant.

## Usage

```hcl
module "dc" {
  source                = "../terraform-azurerm-compeer-windows-vm"
  name                  = "vm-dc01"
  resource_group_name   = module.rg.name
  location              = "eastus2"
  network_interface_ids = [module.nic.id]
  admin_password        = var.dc_admin_password

  source_image_reference = {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-datacenter-azure-edition"
    version   = "latest"
  }

  tags = module.tags.tags
}
```

## Inputs (selected)

| Input | Type | Default | Notes |
|---|---|---|---|
| `name` / `resource_group_name` / `location` | string | — | ForceNew |
| `network_interface_ids` | list(string) | — | first is primary; ≥1 required |
| `admin_password` | string (sensitive) | — | validated: ≥14 chars, upper/lower/digit/special |
| `computer_name` | string | derived | ≤15 chars; default = sanitised `name` prefix |
| `zone` / `availability_set_id` | string | `null` | mutually exclusive (precondition); `zone` is ForceNew |
| `source_image_id` / `source_image_reference` | string / object | `null` | exactly one required (preconditions) |
| `os_disk` | object | Premium_LRS / ReadWrite | `caching`, `storage_account_type`, sizes |
| `patch_mode` | string | `AutomaticByPlatform` | validated Manual/AutomaticByOS/AutomaticByPlatform |
| `secure_boot_enabled` / `vtpm_enabled` / `encryption_at_host_enabled` | bool | `true` | Trusted Launch + host encryption on by default |
| `identity` | object | `null` | UserAssigned requires ≥1 `identity_ids` (precondition) |
| `timeouts` | object | `{}` | passthrough |

## Outputs

`id`, `name`, `computer_name`, `identity`, `identity_principal_id`, `private_ips`.

## Lifecycle contract

| Change | Result |
|---|---|
| `tags`, `vm_size` (resize), `patch_mode`, `license_type`, `identity`, `boot_diagnostics`, `allow_extension_operations` | **update in place** |
| `admin_password` | update in place (reset) |
| `os_disk.disk_size_gb` increase | update in place |
| `name`, `computer_name`, `zone`, `availability_set_id`, `source_image_*`, `admin_username`, `os_disk.storage_account_type`, `encryption_at_host_enabled` | **replace** (Azure ForceNew) |

**State exposure:** `admin_password` is stored in Terraform state. Protect the
backend; prefer feeding it from Key Vault via a data source in the caller.

## Migration

`enable_automatic_updates` renamed to `automatic_updates_enabled` (azurerm-4.x
current name). Added `patch_mode` validation and descriptions. Fixed a
precondition that dereferenced `var.identity` before the null check.

## Tests

`terraform test` (offline): Trusted-Launch defaults, zone/availability-set
exclusivity, weak-password rejection, patch_mode validation.
