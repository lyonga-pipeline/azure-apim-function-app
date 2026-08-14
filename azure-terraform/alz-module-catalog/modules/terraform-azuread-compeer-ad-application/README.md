# Azure AD Application

This module creates an Azure Active Directory (AD) Application, which can be used to integrate applications and services with Azure AD for user authentication and permissions. The configuration can be complex with many optional parameters, dynamic blocks, and conditional assignments.

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.2 |
| <a name="requirement_azuread"></a> [azuread](#requirement\_azuread) | Appropriate version needed |

---

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azuread"></a> [azuread](#provider\_azuread) | "~> 3.0" |

---

## Modules

No modules.

---

## Resources

| Name | Type |
|------|------|
| [azuread_application.ad_application](https://registry.terraform.io/providers/hashicorp/azuread/2.41.0/docs/resources/application) | resource |
| [azuread_client_config.current](https://registry.terraform.io/providers/hashicorp/azuread/2.41.0/docs/data-sources/client_config) | data source |

### Resource Block

```hcl
resource "azuread_application" "ad_application" {
  ...
}
```

This declares a resource of type `azuread_application` with a local name `ad_application`.

#### Dynamic Blocks

The configuration leverages the `dynamic` block capability of Terraform, providing flexibility based on input variables:

##### Dynamic API Block

This block is used to define API configurations related to the AD application.

```hcl
dynamic "api" {
  ...
}
```

##### Dynamic App Role Block

This block defines roles that can be assigned to users, groups, or applications in Azure AD.

```hcl
dynamic "app_role" {
  ...
}
```

##### Dynamic Optional Claims Block

This block specifies claims that are not included by default in tokens.

```hcl
dynamic "optional_claims" {
  ...
}
```

##### Dynamic Public Client Block

This block allows you to specify configurations specific to public clients.

```hcl
dynamic "public_client" {
  ...
}
```

##### Dynamic Web Block

Configurations related to web applications are defined within this block.

```hcl
dynamic "web" {
  ...
}
```

---

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_display_name"></a> [display\_name](#input\_display\_name) | The display name for the application. | `string` | n/a | yes |
| <a name="input_api"></a> [api](#input\_api) | API configuration for the Azure AD application. | ```list(object({ known_client_applications = list(string) mapped_claims_enabled = bool oauth2_permission_scope = list(object({ admin_consent_description = string admin_consent_display_name = string enabled = bool id = string type = string user_consent_description = string user_consent_display_name = string value = string })) requested_access_token_version = number }))``` | `[]` | no |
| <a name="input_app_role"></a> [app\_role](#input\_app\_role) | App Role configuration for the Azure AD application. | ```list(object({ allowed_member_types = list(string) description = string display_name = string enabled = bool id = string value = string }))``` | `[]` | no |
| <a name="input_client_secret_dispaly_name"></a> [client\_secret\_dispaly\_name](#input\_client\_secret\_dispaly\_name) | A display name for the password. Changing this field forces a new resource to be created. | `string` | `null` | no |
| <a name="input_description"></a> [description](#input\_description) | A description of the application, as shown to end users. | `string` | `null` | no |
| <a name="input_device_only_auth_enabled"></a> [device\_only\_auth\_enabled](#input\_device\_only\_auth\_enabled) | Specifies whether this application supports device authentication without a user. | `bool` | `false` | no |
| <a name="input_fallback_public_client_enabled"></a> [fallback\_public\_client\_enabled](#input\_fallback\_public\_client\_enabled) | Specifies whether the application is a public client. | `bool` | `false` | no |
| <a name="input_group_membership_claims"></a> [group\_membership\_claims](#input\_group\_membership\_claims) | Configures the groups claim issued in a user or OAuth 2.0 access token that the app expects. | `set(string)` | `[]` | no |
| <a name="input_identifier_uris"></a> [identifier\_uris](#input\_identifier\_uris) | A set of user-defined URI(s) that uniquely identify an application. | `list(string)` | `[]` | no |
| <a name="input_logo_image"></a> [logo\_image](#input\_logo\_image) | A raw base64-encoded string representing the application's logo image. | `string` | `null` | no |
| <a name="input_marketing_url"></a> [marketing\_url](#input\_marketing\_url) | URL of the application's marketing page. | `string` | `null` | no |
| <a name="input_notes"></a> [notes](#input\_notes) | User-specified notes relevant for the management of the application. | `string` | `null` | no |
| <a name="input_oauth2_post_response_required"></a> [oauth2\_post\_response\_required](#input\_oauth2\_post\_response\_required) | Specifies whether Azure AD allows POST requests, as opposed to GET requests, as part of OAuth 2.0 token requests. | `bool` | `false` | no |
| <a name="input_optional_claims"></a> [optional\_claims](#input\_optional\_claims) | Optional Claims configuration for the Azure AD application. | ```object({ access_token = list(object({ additional_properties = list(string) essential = bool name = string source = string })) id_token = list(object({ additional_properties = list(string) essential = bool name = string source = string })) saml2_token = list(object({ additional_properties = list(string) essential = bool name = string source = string })) })``` | ```{ "access_token": [], "id_token": [], "saml2_token": [] }``` | no |
| <a name="input_owners"></a> [owners](#input\_owners) | A set of object IDs of principals that will be granted ownership of the application. | `list(string)` | `[]` | no |
| <a name="input_prevent_duplicate_names"></a> [prevent\_duplicate\_names](#input\_prevent\_duplicate\_names) | If true, will return an error if an existing application is found with the same name. | `bool` | `false` | no |
| <a name="input_privacy_statement_url"></a> [privacy\_statement\_url](#input\_privacy\_statement\_url) | URL of the application's privacy statement. | `string` | `null` | no |
| <a name="input_public_client"></a> [public\_client](#input\_public\_client) | Public Client configuration for the Azure AD application. | ```list(object({ redirect_uris = list(string) }))``` | `[]` | no |
| <a name="input_required_resource_access"></a> [required\_resource\_access](#input\_required\_resource\_access) | Configuration for required resource access | ```list(object({ resource_app_id = string resource_access = list(object({ id = string type = string })) }))``` | `[]` | no |
| <a name="input_service_management_reference"></a> [service\_management\_reference](#input\_service\_management\_reference) | References application context information from a Service or Asset Management database. | `string` | `null` | no |
| <a name="input_sign_in_audience"></a> [sign\_in\_audience](#input\_sign\_in\_audience) | The Microsoft account types that are supported for the current application. | `string` | `null` | no |
| <a name="input_single_page_application"></a> [single\_page\_application](#input\_single\_page\_application) | Configuration for single page application | ```object({ redirect_uris = list(string) })``` | `null` | no |
| <a name="input_support_url"></a> [support\_url](#input\_support\_url) | URL of the application's support page. | `string` | `null` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | A set of tags to apply to the application for configuring specific behaviours. | `list(string)` | `[]` | no |
| <a name="input_template_id"></a> [template\_id](#input\_template\_id) | Unique ID for a templated application in the Azure AD App Gallery, from which to create the application. | `string` | `null` | no |
| <a name="input_terms_of_service_url"></a> [terms\_of\_service\_url](#input\_terms\_of\_service\_url) | URL of the application's terms of service statement. | `string` | `null` | no |
| <a name="input_web"></a> [web](#input\_web) | Configuration for web application settings | ```object({ homepage_url = optional(string) logout_url = optional(string) redirect_uris = list(string) implicit_grant = object({ access_token_issuance_enabled = optional(bool) id_token_issuance_enabled = optional(bool) }) })``` | `null` | no |

---

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_app_role_ids"></a> [app\_role\_ids](#output\_app\_role\_ids) | A mapping of app role values to app role IDs, intended to be useful when referencing app roles in other resources in your configuration. |
| <a name="output_client_id"></a> [client\_id](#output\_client\_id) | The application's client ID (formerly called application ID). |
| <a name="output_id"></a> [id](#output\_id) | The application's resource ID. |
| <a name="output_oauth2_permission_scope_ids"></a> [oauth2\_permission\_scope\_ids](#output\_oauth2\_permission\_scope\_ids) | A mapping of OAuth2.0 permission scope values to scope IDs, intended to be useful when referencing permission scopes in other resources in your configuration. |
| <a name="output_object_id"></a> [object\_id](#output\_object\_id) | The application's object ID. |
| <a name="output_publisher_domain"></a> [publisher\_domain](#output\_publisher\_domain) | The verified publisher domain for the application. |

---

## Conclusion

This Terraform module enables the provisioning and management of Azure AD Applications. It offers granularity over the application's settings, providing a great deal of flexibility and security for integration scenarios.
