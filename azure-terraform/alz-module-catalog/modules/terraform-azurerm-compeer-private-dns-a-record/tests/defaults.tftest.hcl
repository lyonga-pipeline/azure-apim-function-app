mock_provider "azurerm" {}
variables {
  records = {
    api = { name = "api", zone_name = "internal.example.com", resource_group_name = "rg-dns", records = ["10.0.1.10"] }
  }
}
run "create" {
  command = apply
  assert {
    condition     = azurerm_private_dns_a_record.this["api"].ttl == 300
    error_message = "ttl should default to 300"
  }
}
run "rejects_empty_records" {
  command = plan
  variables { records = { bad = { name = "x", zone_name = "z", resource_group_name = "rg", records = [] } } }
  expect_failures = [var.records]
}
