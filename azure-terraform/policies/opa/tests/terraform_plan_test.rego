package compeer.lz

test_secure_storage_passes {
  count(deny) == 0 with input as {
    "resource_changes": [{
      "address": "azurerm_storage_account.example",
      "type": "azurerm_storage_account",
      "change": {
        "actions": ["create"],
        "after": {
          "location": "eastus2",
          "public_network_access_enabled": false,
          "tags": {
            "env": "np1",
            "application": "example",
            "bt_owner": "cloud",
            "source_repo": "ado://example",
            "tf_workspace": "lz-workload-example-np1",
            "recovery": "standard",
            "cost_center": "cc-1001",
            "data_classification": "internal",
            "compliance_boundary": "finserv"
          }
        }
      }
    }]
  }
}

test_public_storage_fails {
  msg := deny[_]
  contains(msg, "public network access") with input as {
    "resource_changes": [{
      "address": "azurerm_storage_account.example",
      "type": "azurerm_storage_account",
      "change": {
        "actions": ["create"],
        "after": {
          "location": "eastus2",
          "public_network_access_enabled": true,
          "tags": {
            "env": "np1",
            "application": "example",
            "bt_owner": "cloud",
            "source_repo": "ado://example",
            "tf_workspace": "lz-workload-example-np1",
            "recovery": "standard",
            "cost_center": "cc-1001",
            "data_classification": "internal",
            "compliance_boundary": "finserv"
          }
        }
      }
    }]
  }
}
