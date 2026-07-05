package compeer.lz

standard_tags := {
	"env": "np1",
	"application": "example",
	"bt_owner": "cloud",
	"source_repo": "ado://example",
	"tf_workspace": "lz-workload-example-np1",
	"recovery": "standard",
	"cost_center": "cc-1001",
	"data_classification": "internal",
	"compliance_boundary": "finserv",
}

test_secure_storage_with_diagnostics_passes if {
	count(deny) == 0 with input as {"resource_changes": [
		{
			"address": "azurerm_storage_account.example",
			"type": "azurerm_storage_account",
			"change": {
				"actions": ["create"],
				"after": {
					"location": "eastus2",
					"public_network_access_enabled": false,
					"min_tls_version": "TLS1_2",
					"shared_access_key_enabled": false,
					"allow_nested_items_to_be_public": false,
					"infrastructure_encryption_enabled": true,
					"tags": standard_tags,
				},
			},
		},
		{
			"address": "azurerm_monitor_diagnostic_setting.storage",
			"type": "azurerm_monitor_diagnostic_setting",
			"change": {
				"actions": ["create"],
				"after": {"target_resource_id": "/subscriptions/000/resourceGroups/rg/providers/Microsoft.Storage/storageAccounts/example"},
			},
		},
	]}
}

test_public_storage_fails if {
	msg := deny[_] with input as {"resource_changes": [{
		"address": "azurerm_storage_account.example",
		"type": "azurerm_storage_account",
		"change": {
			"actions": ["create"],
			"after": {
				"location": "eastus2",
				"public_network_access_enabled": true,
				"tags": standard_tags,
			},
		},
	}]}
	contains(msg, "public network access")
}

test_hcp_wrapped_public_storage_fails if {
	msg := deny[_] with input as {"plan": {"resource_changes": [{
		"address": "azurerm_storage_account.example",
		"type": "azurerm_storage_account",
		"change": {
			"actions": ["create"],
			"after": {
				"location": "eastus2",
				"public_network_access_enabled": true,
				"tags": standard_tags,
			},
		},
	}]}}
	contains(msg, "public network access")
}

test_sql_public_network_fails if {
	msg := deny[_] with input as {"resource_changes": [{
		"address": "azurerm_mssql_server.example",
		"type": "azurerm_mssql_server",
		"change": {
			"actions": ["create"],
			"after": {
				"location": "eastus2",
				"public_network_access_enabled": true,
				"minimum_tls_version": "1.2",
				"azuread_authentication_only": true,
				"tags": standard_tags,
			},
		},
	}]}
	contains(msg, "SQL Server")
}

test_key_vault_without_rbac_fails if {
	msg := deny[_] with input as {"resource_changes": [{
		"address": "azurerm_key_vault.example",
		"type": "azurerm_key_vault",
		"change": {
			"actions": ["create"],
			"after": {
				"location": "eastus2",
				"public_network_access_enabled": false,
				"rbac_authorization_enabled": false,
				"purge_protection_enabled": true,
				"soft_delete_retention_days": 90,
				"tags": standard_tags,
			},
		},
	}]}
	contains(msg, "RBAC authorization")
}

test_key_vault_without_rbac_fails_with_legacy_provider_field if {
	msg := deny[_] with input as {"resource_changes": [{
		"address": "azurerm_key_vault.example",
		"type": "azurerm_key_vault",
		"change": {
			"actions": ["create"],
			"after": {
				"location": "eastus2",
				"public_network_access_enabled": false,
				"enable_rbac_authorization": false,
				"purge_protection_enabled": true,
				"soft_delete_retention_days": 90,
				"tags": standard_tags,
			},
		},
	}]}
	contains(msg, "RBAC authorization")
}

test_function_app_public_network_fails if {
	msg := deny[_] with input as {"resource_changes": [{
		"address": "azurerm_windows_function_app.example",
		"type": "azurerm_windows_function_app",
		"change": {
			"actions": ["create"],
			"after": {
				"location": "eastus2",
				"https_only": true,
				"public_network_access_enabled": true,
				"ftp_publish_basic_authentication_enabled": false,
				"webdeploy_publish_basic_authentication_enabled": false,
				"site_config": [{
					"minimum_tls_version": "1.2",
					"scm_minimum_tls_version": "1.2",
				}],
				"tags": standard_tags,
			},
		},
	}]}
	contains(msg, "public network access")
}

test_function_app_without_managed_identity_fails if {
	msg := deny[_] with input as {"resource_changes": [{
		"address": "azurerm_windows_function_app.example",
		"type": "azurerm_windows_function_app",
		"change": {
			"actions": ["create"],
			"after": {
				"location": "eastus2",
				"https_only": true,
				"public_network_access_enabled": false,
				"ftp_publish_basic_authentication_enabled": false,
				"webdeploy_publish_basic_authentication_enabled": false,
				"site_config": [{
					"minimum_tls_version": "1.2",
					"scm_minimum_tls_version": "1.2",
				}],
				"tags": standard_tags,
			},
		},
	}]}
	contains(msg, "managed identity")
}

test_missing_diagnostics_fails_for_required_resource_type if {
	msg := deny[_] with input as {"resource_changes": [{
		"address": "azurerm_virtual_network.example",
		"type": "azurerm_virtual_network",
		"change": {
			"actions": ["create"],
			"after": {
				"location": "eastus2",
				"tags": standard_tags,
			},
		},
	}]}
	contains(msg, "requires diagnostic settings")
}

test_unapproved_module_source_fails if {
	msg := deny[_] with input as {
		"resource_changes": [],
		"configuration": {"root_module": {"module_calls": {"storage": {"source": "git::https://example.com/unapproved/storage.git"}}}},
	}
	contains(msg, "module source")
}

test_hcp_wrapped_unapproved_module_source_fails if {
	msg := deny[_] with input as {"plan": {
		"resource_changes": [],
		"configuration": {"root_module": {"module_calls": {"storage": {"source": "git::https://example.com/unapproved/storage.git"}}}},
	}}
	contains(msg, "module source")
}
