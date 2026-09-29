# Closes keyed-output and validation gaps left by defaults.tftest.hcl:
# route_table_names, private_endpoint_names, load_balancer_names,
# disk_names, and subnet_names had zero coverage; abbreviation and
# key_vault_name_token had no run proving their regex actually rejects bad
# input.

run "route_table_names_keyed_output" {
  command = apply
  variables {
    region           = "centralus"
    environment      = "prod"
    component        = "connectivity"
    route_table_keys = ["to_firewall", "to_internet"]
  }

  assert {
    condition     = output.route_table_names["to_firewall"] == "cus-prod-to_firewall-rt" || output.route_table_names["to_firewall"] == "cus-prod-to-firewall-rt"
    error_message = "route_table_names should follow <region>-<env>-<key>-rt"
  }
  assert {
    condition     = length(output.route_table_names) == 2
    error_message = "route_table_names should have one entry per key"
  }
}

run "private_endpoint_names_keyed_output" {
  command = apply
  variables {
    region                = "centralus"
    environment           = "prod"
    component             = "management"
    private_endpoint_keys = ["kv-platform", "sa-diag"]
  }

  assert {
    condition     = length(output.private_endpoint_names) == 2
    error_message = "private_endpoint_names should have one entry per key"
  }
}

run "load_balancer_names_keyed_output" {
  command = apply
  variables {
    region             = "centralus"
    environment        = "prod"
    component          = "connectivity"
    load_balancer_keys = ["ingress"]
  }

  assert {
    condition     = output.load_balancer_names["ingress"] == "${output.stem}-ingress-ilb"
    error_message = "load_balancer_names should follow <stem>-<key>-ilb"
  }
}

run "disk_names_keyed_output" {
  command = apply
  variables {
    region      = "centralus"
    environment = "prod"
    component   = "management"
    disk_keys   = ["ad-data"]
  }

  assert {
    condition     = output.disk_names["ad-data"] == "cus-prod-ad-data-disk"
    error_message = "disk_names should follow <region>-<env>-<key>-disk"
  }
}

run "subnet_names_keyed_output_non_connectivity_root" {
  command = apply
  variables {
    region      = "centralus"
    environment = "prod"
    component   = "management"
    subnet_keys = ["ad-data"]
  }

  assert {
    condition     = output.subnet_names["ad-data"] == "prod-ad-data-subnet"
    error_message = "subnet_names should follow <env>-<key>-subnet on a non-connectivity root"
  }
}

run "rejects_bad_abbreviation" {
  command = plan
  variables {
    region       = "centralus"
    environment  = "prod"
    component    = "management"
    abbreviation = "1mgmt" # must start with a letter
  }
  expect_failures = [var.abbreviation]
}

run "rejects_bad_key_vault_name_token" {
  command = plan
  variables {
    region               = "centralus"
    environment          = "prod"
    component            = "management"
    key_vault_name_token = "bad--token" # consecutive hyphens not allowed
  }
  expect_failures = [var.key_vault_name_token]
}
