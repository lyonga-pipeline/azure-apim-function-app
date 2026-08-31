mock_provider "azurerm" {}
variables {
  name                = "alert-cpu"
  resource_group_name = "rg-mon"
  scopes              = ["/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.Compute/virtualMachines/vm01"]
  criteria = {
    cpu = { metric_namespace = "Microsoft.Compute/virtualMachines", metric_name = "Percentage CPU", aggregation = "Average", operator = "GreaterThan", threshold = 90 }
  }
}
run "create" {
  command = apply
  assert {
    condition     = length(azurerm_monitor_metric_alert.this.criteria) == 1
    error_message = "expected one criteria block"
  }
}
