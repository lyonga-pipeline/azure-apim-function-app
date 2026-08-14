## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.2 |
| <a name="requirement_azuread"></a> [azuread](#requirement\_azuread) | 2.41.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azuread"></a> [azuread](#provider\_azuread) | 2.41.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [azuread_group.ad_group](https://registry.terraform.io/providers/hashicorp/azuread/2.41.0/docs/resources/group) | resource |
| [azuread_client_config.current](https://registry.terraform.io/providers/hashicorp/azuread/2.41.0/docs/data-sources/client_config) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_display_name"></a> [display\_name](#input\_display\_name) | The display name for the group. | `string` | n/a | yes |
| <a name="input_administrative_unit_ids"></a> [administrative\_unit\_ids](#input\_administrative\_unit\_ids) | The object IDs of administrative units in which the group is a member. If specified, new groups will be created in the scope of the first administrative unit and added to the others. If empty, new groups will be created at the tenant level. | `set(string)` | `null` | no |
| <a name="input_assignable_to_role"></a> [assignable\_to\_role](#input\_assignable\_to\_role) | Indicates whether this group can be assigned to an Azure Active Directory role. | `bool` | `null` | no |
| <a name="input_auto_subscribe_new_members"></a> [auto\_subscribe\_new\_members](#input\_auto\_subscribe\_new\_members) | Indicates whether new members added to the group will be auto-subscribed to receive email notifications. | `bool` | `null` | no |
| <a name="input_behaviors"></a> [behaviors](#input\_behaviors) | A set of behaviors for a Microsoft 365 group. | `set(string)` | `null` | no |
| <a name="input_description"></a> [description](#input\_description) | The description for the group. | `string` | `null` | no |
| <a name="input_dynamic_membership"></a> [dynamic\_membership](#input\_dynamic\_membership) | Configuration for the dynamic\_membership block. | ```object({ enabled = bool rule = string })``` | `null` | no |
| <a name="input_external_senders_allowed"></a> [external\_senders\_allowed](#input\_external\_senders\_allowed) | Indicates whether people external to the organization can send messages to the group. | `bool` | `null` | no |
| <a name="input_hide_from_address_lists"></a> [hide\_from\_address\_lists](#input\_hide\_from\_address\_lists) | Indicates whether the group is displayed in certain parts of the Outlook user interface. | `bool` | `null` | no |
| <a name="input_hide_from_outlook_clients"></a> [hide\_from\_outlook\_clients](#input\_hide\_from\_outlook\_clients) | Indicates whether the group is displayed in Outlook clients. | `bool` | `null` | no |
| <a name="input_mail_enabled"></a> [mail\_enabled](#input\_mail\_enabled) | Whether the group is a mail-enabled. | `bool` | `null` | no |
| <a name="input_mail_nickname"></a> [mail\_nickname](#input\_mail\_nickname) | The mail alias for the group. | `string` | `null` | no |
| <a name="input_members"></a> [members](#input\_members) | A set of members who should be present in this group. | `list(string)` | `null` | no |
| <a name="input_onpremises_group_type"></a> [onpremises\_group\_type](#input\_onpremises\_group\_type) | The on-premises group type that the AAD group will be written as. | `string` | `null` | no |
| <a name="input_owners"></a> [owners](#input\_owners) | A set of object IDs of principals that will be granted ownership of the group. | `set(string)` | `null` | no |
| <a name="input_prevent_duplicate_names"></a> [prevent\_duplicate\_names](#input\_prevent\_duplicate\_names) | Return an error if an existing group is found with the same name. | `bool` | `null` | no |
| <a name="input_provisioning_options"></a> [provisioning\_options](#input\_provisioning\_options) | A set of provisioning options for a Microsoft 365 group. | `set(string)` | `null` | no |
| <a name="input_security_enabled"></a> [security\_enabled](#input\_security\_enabled) | Whether the group is a security group for controlling access. | `bool` | `null` | no |
| <a name="input_theme"></a> [theme](#input\_theme) | The colour theme for a Microsoft 365 group. | `string` | `null` | no |
| <a name="input_types"></a> [types](#input\_types) | A set of group types to configure for the group. | `set(string)` | `null` | no |
| <a name="input_visibility"></a> [visibility](#input\_visibility) | The group join policy and group content visibility. | `string` | `null` | no |
| <a name="input_writeback_enabled"></a> [writeback\_enabled](#input\_writeback\_enabled) | Whether the group will be written back to the on-premises AD. | `bool` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_object_id"></a> [object\_id](#output\_object\_id) | The object ID of the group. |
