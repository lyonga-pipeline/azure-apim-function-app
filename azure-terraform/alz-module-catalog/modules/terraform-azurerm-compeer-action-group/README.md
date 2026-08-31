# terraform-azurerm-compeer-action-group

Azure Monitor Action Group. One resource, full receiver surface (all receiver
families), each family a `map(object)` keyed by a stable caller name so adding one
receiver never reorders the others.

`terraform-azurerm-compeer-actiongroup` has an identical interface; both are kept
and maintained to the same standard.

## Usage

```hcl
module "ag" {
  source              = "../terraform-azurerm-compeer-action-group"
  name                = "ag-platform-critical"
  resource_group_name = module.rg.name
  short_name          = "platcrit"

  receivers = {
    email   = { oncall = { email_address = "oncall@example.com" } }
    webhook = { pagerduty = { service_uri = var.pd_uri } }
  }

  tags = module.tags.tags
}
```

## Inputs

| Input | Type | Default | Notes |
|---|---|---|---|
| `name` | string | - | ForceNew |
| `resource_group_name` | string | - | ForceNew |
| `short_name` | string | - | validated 1-12 chars |
| `enabled` | bool | `true` | update in place |
| `receivers` | object | `{}` | per-family `map(object)`: `email`, `webhook`, `sms`, `voice`, `arm_role`, `automation_runbook`, `azure_app_push`, `azure_function`, `event_hub`, `itsm`, `logic_app` |
| `tags` | map(string) | `{}` | update in place |
| `timeouts` | object | `{}` | passthrough |

## Outputs

`id`, `name`, `resource_group_name`, `short_name`, `enabled`.

## Lifecycle contract

| Change | Result |
|---|---|
| `enabled`, `tags`, any receiver add/remove/edit | **update in place** - receivers are inline blocks; the group is never replaced |
| `name`, `resource_group_name` | **replace** (ForceNew) |

State exposure: webhook/function URIs and ITSM connection IDs passed in `receivers`
are stored in state. Treat them as secret-adjacent.

## Migration

`short_name` is now validated (1-12 chars). No other interface change.

## Tests

`terraform test` (offline): create with email+webhook receivers, additive receiver
add, `short_name` length validation.
