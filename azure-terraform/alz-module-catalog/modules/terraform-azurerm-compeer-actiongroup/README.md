# terraform-azurerm-compeer-actiongroup

> **⚠ Non-canonical — use [`terraform-azurerm-compeer-action-group`](../terraform-azurerm-compeer-action-group) instead** (hyphenated; consumed by platform-management). This module is kept working for backward compatibility; do not pick it for new work.


Azure Monitor Action Group. Interface is **identical** to
`terraform-azurerm-compeer-action-group` (the redesign converged them); both are
kept and maintained to the same standard. See that module's README for the full
input/output/lifecycle documentation.

## Usage

```hcl
module "ag" {
  source              = "../terraform-azurerm-compeer-actiongroup"
  name                = "ag-platform-critical"
  resource_group_name = module.rg.name
  short_name          = "platcrit"

  receivers = {
    email = { oncall = { email_address = "oncall@example.com" } }
  }
}
```

## Lifecycle contract

Receivers are inline `map(object)` blocks keyed by stable name — every receiver
add/remove/edit and `enabled`/`tags` change is **update in place**. `name` and
`resource_group_name` are ForceNew.

## Migration

The legacy `actiongrp_*` list variables and `action_group_name` /
`action_group_short_name` are replaced by `name`, `short_name` and the typed
`receivers` object. Map the old flat receiver lists into the corresponding
`receivers.<family>` map keyed by the old `name` field. `short_name` is now
validated (1-12 chars). The stale `test/` fixture was removed in favour of
`tests/defaults.tftest.hcl`.

## Tests

`terraform test` (offline): create with email+webhook receivers, additive receiver
add, `short_name` validation.
