variables {
  workload    = "hub"
  environment = "prod"
  region      = "centralus"
}

run "names" {
  command = apply
  assert {
    condition     = output.names.virtual_network == "vnet-cmp-hub-prod-cus-001"
    error_message = "vnet name not built as expected"
  }
  assert {
    condition     = output.names.resource_group == "rg-cmp-hub-prod-cus-001"
    error_message = "rg name not built as expected"
  }
  assert {
    condition     = output.names_nodash.storage_account == "stcmphubprodcus001"
    error_message = "no-dash storage name not built as expected"
  }
  assert {
    condition     = output.region_short == "cus"
    error_message = "region short code wrong"
  }
}

run "rejects_bad_env" {
  command = plan
  variables { environment = "production" }
  expect_failures = [var.environment]
}

run "no_dash_truncates_to_24" {
  command = apply
  variables {
    workload = "verylongworkloadname"
    instance = "001"
  }
  assert {
    condition     = length(output.names_nodash.storage_account) <= 24
    error_message = "no-dash name exceeds 24 chars"
  }
}
