# Azure App Configuration

This module provides Terraform configurations for creating and managing Azure App Configurations, Features, and Keys. Azure App Configuration is a managed service that helps developers centralize their application and feature settings without hard-coding them into their applications.

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.2 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | >=3.11, < 5.0 |

---

## Resources

### Azure App Configuration

| Name | Type |
|------|------|
| [azurerm_app_configuration.app_config](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/app_configuration) | resource |

### Azure App Configuration Feature

| Name | Type |
|------|------|
| [azurerm_app_configuration_feature.app_config_feature](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/app_configuration_feature) | resource |

### Azure App Configuration Key

| Name | Type |
|------|------|
| [azurerm_app_configuration_key.app_config_key](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/app_configuration_key) | resource |

---

## Inputs

| Name                              | Description                                                                                                               | Type                                                                                                                                                                    | Default | Required/Opt |
|-----------------------------------|---------------------------------------------------------------------------------------------------------------------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------|---------|--------------|
| `app_config_name`                 | Specifies the name of the App Configuration                                                                               | string                                                                                                                                                                  | N/A     | Required     |
| `resource_group_name`             | The name of the resource group                                                                                            | string                                                                                                                                                                  | N/A     | Required     |
| `location`                        | Specifies the supported Azure location                                                                                    | string                                                                                                                                                                  | N/A     | Required     |
| `configuration_store_id`          | Specifies the id of the App Configuration                                                                                 | string                                                                                                                                                                  | N/A     | Required     |
| `feature_name`                    | The name of the App Configuration Feature                                                                                 | string                                                                                                                                                                  | N/A     | Required     |
| `percentage_filter_value`         | A list of numbers representing the value of the percentage required to enable this feature                                 | number                                                                                                                                                                  | N/A     | Required     |
| `timewindow_filter`               | A block representing a feature filter of type Microsoft.TimeWindow                                                         | object({start=optional(string), end=optional(string)})                                                                                                                  | N/A     | Required     |
| `app_config_key_name`             | The name of the App Configuration Key to create                                                                           | string                                                                                                                                                                  | N/A     | Required     |
| `create_app_config`               | Flag to control the creation of App Configuration                                                                         | bool                                                                                                                                                                    | false   | Optional     |
| `create_app_config_feature`       | Flag to control the creation of App Configuration Feature                                                                 | bool                                                                                                                                                                    | false   | Optional     |
| `create_app_config_key`           | Flag to control the creation of App Configuration Key                                                                     | bool                                                                                                                                                                    | false   | Optional     |
| `app_config_sku`                  | The SKU name of the App Configuration                                                                                     | string                                                                                                                                                                  | null    | Optional     |
| `app_config_local_auth`           | Whether local authentication methods is enabled                                                                           | bool                                                                                                                                                                    | null    | Optional     |
| `app_config_public_access`        | The Public Network Access setting of the App Configuration                                                                | string                                                                                                                                                                  | null    | Optional     |
| `app_config_purge_protection`     | Whether Purge Protection is enabled                                                                                       | bool                                                                                                                                                                    | null    | Optional     |
| `app_config_retention_days`       | The number of days items should be retained for once soft-deleted                                                          | number                                                                                                                                                                  | null    | Optional     |
| `identity`                        | value                                                                                                                     | list(object({type=string, identity_ids=optional(string)}))                                                                                                              | null    | Optional     |
| `encryption`                      | value                                                                                                                     | list(object({key_vault_key_identifier=optional(string), identity_client_id=optional(string)}))                                                                          | null    | Optional     |
| `app_config_tags`                 | A mapping of tags to assign to the resource                                                                               | map(string)                                                                                                                                                             | null    | Optional     |
| `feature_description`             | The description of the App Configuration Feature                                                                          | string                                                                                                                                                                  | null    | Optional     |
| `feature_enabled`                 | The status of the App Configuration Feature                                                                               | bool                                                                                                                                                                    | false   | Optional     |
| `feature_key`                     | The key of the App Configuration Feature                                                                                  | string                                                                                                                                                                  | null    | Optional     |
| `feature_label`                   | The label of the App Configuration Feature                                                                                | string                                                                                                                                                                  | null    | Optional     |
| `feature_locked`                  | Should this App Configuration Feature be Locked to prevent changes?                                                       | bool                                                                                                                                                                    | false   | Optional     |
| `feature_tags`                    | A mapping of tags to assign to the resource                                                                               | map(string)                                                                                                                                                             | null    | Optional     |
| `targeting_filter`                | A targeting_filter block represents a feature filter of type Microsoft.Targeting                                          | object({default_rollout_percentage=optional(number), users=optional(list(string)), groups=list(object({name=string, rollout_percentage=number}))})                        | null    | Optional     |
| `app_config_key_content_type`     | The content type of the App Configuration Key                                                                             | string                                                                                                                                                                  | null    | Optional     |
| `app_config_key_label`            | The label of the App Configuration Key                                                                                    | string                                                                                                                                                                  | null    | Optional     |
| `app_config_key_value`            | The value of the App Configuration Key                                                                                    | string                                                                                                                                                                  | null    | Optional     |
| `app_config_key_locked`           | Should this App Configuration Key be Locked to prevent changes?                                                           | bool                                                                                                                                                                    | false   | Optional     |
| `app_config_key_type`             | The type of the App Configuration Key                                                                                     | string                                                                                                                                                                  | "kv"    | Optional     |
| `app_config_key_vault_key_reference` | The ID of the vault secret this App Configuration Key refers to                                                          | string                                                                                                                                                                  | null    | Optional     |
| `app_config_key_tags`             | A mapping of tags to assign to the resource                                                                               | map(string)                                                                                                                                                             | null    | Optional     |

---

## Outputs

Here are the output values you can expect when deploying this configuration:

| Name                    | Description                              |
|-------------------------|------------------------------------------|
| `app_config_id`         | The App Configuration ID.                |
| `app_config_endpoint`   | The URL of the App Configuration.        |
| `app_config_feature_id` | The App Configuration Feature ID         |
| `app_config_key_id`     | The App Configuration Key ID             |

---

## Conclusion

This Terraform module offers a seamless way to create and manage Azure App Configuration, allowing developers to manage application settings and features centrally. Proper configuration ensures the secure and efficient management of application configurations.

---
