## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.2 |
| <a name="requirement_azuread"></a> [azuread](#requirement\_azuread) | 2.41.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azuread"></a> [azuread](#provider\_azuread) | ~> 3.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [azuread_service_principal.service_principal](https://registry.terraform.io/providers/hashicorp/azuread/2.41.0/docs/resources/service_principal) | resource |
| [azuread_client_config.current](https://registry.terraform.io/providers/hashicorp/azuread/2.41.0/docs/data-sources/client_config) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_client_id"></a> [client\_id](#input\_client\_id) | The client ID of the application. | `string` | n/a | yes |
| <a name="input_account_enabled"></a> [account\_enabled](#input\_account\_enabled) | Whether the service principal account is enabled. | `bool` | `true` | no |
| <a name="input_alternative_names"></a> [alternative\_names](#input\_alternative\_names) | A set of alternative names, used to retrieve service principals by subscription, identify resource group and full resource ids for managed identities. | `list(string)` | `[]` | no |
| <a name="input_app_role_assignment_required"></a> [app\_role\_assignment\_required](#input\_app\_role\_assignment\_required) | Whether this service principal requires an app role assignment to a user or group before Azure AD will issue a user or access token to the application. | `bool` | `false` | no |
| <a name="input_description"></a> [description](#input\_description) | A description of the service principal provided for internal end-users. | `string` | `""` | no |
| <a name="input_feature_tags"></a> [feature\_tags](#input\_feature\_tags) | Configuration for feature tags. | ```list(object({ custom_single_sign_on = optional(bool) enterprise = optional(bool) gallery = optional(bool) hide = optional(bool) }))``` | `[]` | no |
| <a name="input_login_url"></a> [login\_url](#input\_login\_url) | The URL where the service provider redirects the user to Azure AD to authenticate. Azure AD uses the URL to launch the application from Microsoft 365 or the Azure AD My Apps. When blank, Azure AD performs IdP-initiated sign-on for applications configured with SAML-based single sign-on.. | `string` | `""` | no |
| <a name="input_notes"></a> [notes](#input\_notes) | A free text field to capture information about the service principal, typically used for operational purposes. | `string` | `""` | no |
| <a name="input_notification_email_addresses"></a> [notification\_email\_addresses](#input\_notification\_email\_addresses) | A free text field to capture information about the service principal, typically used for operational purposes. | `list(string)` | `[]` | no |
| <a name="input_owners"></a> [owners](#input\_owners) | A set of object IDs of principals that will be granted ownership of the service principal. Supported object types are users or service principals. By default, no owners are assigned. | `list(string)` | `[]` | no |
| <a name="input_preferred_single_sign_on_mode"></a> [preferred\_single\_sign\_on\_mode](#input\_preferred\_single\_sign\_on\_mode) | The preferred single sign-on mode. | `string` | `""` | no |
| <a name="input_saml_single_sign_on"></a> [saml\_single\_sign\_on](#input\_saml\_single\_sign\_on) | Configuration for SAML single sign-on. | ```list(object({ relay_state = optional(string) }))``` | `[]` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags for the service principal. | `list(string)` | `[]` | no |
| <a name="input_use_existing"></a> [use\_existing](#input\_use\_existing) | The single sign-on mode configured for this application. Azure AD uses the preferred single sign-on mode to launch the application from Microsoft 365 or the Azure AD My Apps. | `bool` | `true` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_object_id"></a> [object\_id](#output\_object\_id) | The application's object ID. |
