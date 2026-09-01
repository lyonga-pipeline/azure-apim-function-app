# terraform-azurerm-compeer-naming

Deterministic CAF-style resource naming. No providers, no resources - pure
functions of `{org, workload, environment, region, instance}`.

```hcl
module "naming" {
  source      = "../../modules/terraform-azurerm-compeer-naming"
  workload    = "hub"
  environment = "prod"
  region      = "centralus"
}

# module.naming.names.virtual_network  => "vnet-cmp-hub-prod-cus-001"
# module.naming.names.resource_group   => "rg-cmp-hub-prod-cus-001"
# module.naming.names_nodash.storage_account => "stcmphubprodcus001"
```

`names` uses the Microsoft CAF recommended abbreviations and the `-` separator.
`names_nodash` is the lower-case, separator-free, <=24-char form for storage
accounts, key vaults, etc. Extend region codes with `region_short_overrides`.

Adopt this in patterns instead of free-text names so `deploy-runbook.tf` §2.4
"naming where technically enforceable" is met by construction.

## Tests

`terraform test` - abbreviation + region-code + no-dash truncation.
