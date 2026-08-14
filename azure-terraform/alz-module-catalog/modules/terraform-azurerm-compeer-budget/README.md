# terraform-azurerm-compeer-budget

Creates Azure consumption budgets at resource group, subscription, or management group scope.

## Scope Selection

Use `scope_type` for new deployments:

- `resource_group`
- `subscription`
- `management_group`

The legacy `create_for_rg` and `create_for_subscription` inputs are still supported for compatibility.

## Enterprise Defaults

- Supports management group budgets for platform hierarchy control.
- Supports subscription budgets for subscription vending outputs.
- Supports multiple named notifications.
- Keeps legacy resource group budget inputs so existing callers can migrate safely.

## Example

```hcl
module "platform_budget" {
  source = "./modules/terraform-azurerm-compeer-budget"

  scope_type      = "subscription"
  subscription_id = "/subscriptions/00000000-0000-0000-0000-000000000000"
  budget_name     = "monthly-platform-budget"
  amount          = 1000
  start_date      = "2026-01-01T00:00:00Z"

  notifications = {
    actual_80 = {
      threshold      = 80
      threshold_type = "Actual"
      contact_emails = ["cloud-finops@example.com"]
    }
    forecast_100 = {
      threshold      = 100
      threshold_type = "Forecasted"
      contact_emails = ["cloud-finops@example.com"]
    }
  }
}
```
