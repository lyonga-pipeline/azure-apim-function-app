# terraform-azurerm-compeer-windows-mssql-vm

Configures SQL Server on an **existing** Windows VM
(`azurerm_mssql_virtual_machine`). The VM, its NICs and data disks are
caller-owned and passed in by `virtual_machine_id`. Pair with
`terraform-azurerm-compeer-windows-vm`.

## Usage

```hcl
module "sql" {
  source             = "../terraform-azurerm-compeer-windows-mssql-vm"
  virtual_machine_id = module.vm.id

  sql_license_type                 = "AHUB"
  sql_connectivity_type            = "PRIVATE"
  sql_connectivity_update_username = "sqladmin"
  sql_connectivity_update_password = var.sql_sa_password

  storage_configuration = {
    disk_type             = "NEW"
    storage_workload_type = "OLTP"
  }
}
```

## Inputs (selected)

| Input | Type | Default | Notes |
|---|---|---|---|
| `virtual_machine_id` | string | — | existing VM; ForceNew |
| `sql_license_type` | string | `PAYG` | validated AHUB/DR/PAYG; ForceNew |
| `sql_connectivity_type` | string | `PRIVATE` | validated LOCAL/PRIVATE/PUBLIC |
| `sql_connectivity_update_username` / `_password` (sensitive) | string | `null` | **required** unless connectivity is `LOCAL` (precondition) |
| `storage_configuration` / `auto_backup` / `assessment` / `key_vault_credential` / `wsfc_domain_credential` | object \| null | `null` | optional blocks |

## Outputs

`id`.

## Lifecycle contract

| Change | Result |
|---|---|
| `sql_connectivity_type` / port, `storage_configuration`, `auto_backup`, `assessment`, `r_services_enabled` | **update in place** |
| `sql_license_type` | **replace** (ForceNew) |
| `virtual_machine_id` | **replace** |

**State exposure:** `sql_connectivity_update_password` and the
`wsfc_domain_credential.*` / `key_vault_credential` passwords are stored in state.

## Migration / fixes applied

- `sql_connectivity_update_username` / `_password` changed from **required** to
  optional (`null`), with a precondition that enforces them only for non-`LOCAL`
  connectivity — the provider treats them as optional.
- Added `sql_connectivity_type` and `sql_license_type` value validation.
- Removed placeholder `managed-disks.tf` / `network-interface.tf` /
  `vm_extension.tf` and `data.tf`; `enable_automatic_updates` on the paired VM
  path renamed to `automatic_updates_enabled`. Output `mssql_virtual_machine_id`
  → `id`.

## Tests

`terraform test` (offline): defaults, LOCAL connectivity needs no creds,
PRIVATE-without-creds rejection, both enum validations.
