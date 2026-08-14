# Azure AD Application Certificate

This module facilitates the creation of an Azure AD Application Certificate. This certificate is essential for apps when they need to authenticate against certain resources or perform token encryption.

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.2 |
| <a name="requirement_azuread"></a> [azuread](#requirement\_azuread) | >= 2.0 |

---

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azuread"></a> [azuread](#provider\_azuread) | ">=2.30.0, < 3.0.0" |

---

## Resources

| Name | Type |
|------|------|
| [azuread_application_certificate.ad_application_certificate](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/resources/application_certificate) | resource |

### Resource Block

```hcl
resource "azuread_application_certificate" "ad_application_certificate" {
  application_object_id = var.application_object_id
  encoding = var.encoding
  end_date = var.end_date
  end_date_relative = var.end_date_relative
  key_id = var.key_id
  start_date = var.start_date
  type = var.type
  value = var.value
}
```

This block declares a resource of type `azuread_application_certificate` which associates a certificate with an Azure AD application.

---

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_application_object_id"></a> [application\_object\_id](#input\_application\_object\_id) | The object ID of the application for which this certificate should be created. | `string` | n/a | yes |
| <a name="input_type"></a> [type](#input\_type) | The type of key/certificate. Must be one of AsymmetricX509Cert or Symmetric. | `string` | n/a | yes |
| <a name="input_value"></a> [value](#input\_value) | The certificate data, which can be PEM encoded, base64 encoded DER or hexadecimal encoded DER. | `string` | n/a | yes |
| <a name="input_encoding"></a> [encoding](#input\_encoding) | Specifies the encoding used for the supplied certificate data. Must be one of pem, base64 or hex. | `string` | `"pem"` | no |
| <a name="input_end_date"></a> [end\_date](#input\_end\_date) | The end date until which the certificate is valid, formatted as an RFC3339 date string. | `string` | `null` | no |
| <a name="input_end_date_relative"></a> [end\_date\_relative](#input\_end\_date\_relative) | A relative duration for which the certificate is valid until, for example 240h (10 days) or 2400h30m. | `string` | `null` | no |
| <a name="input_key_id"></a> [key\_id](#input\_key\_id) | A UUID used to uniquely identify this certificate. | `string` | `null` | no |
| <a name="input_start_date"></a> [start\_date](#input\_start\_date) | The start date from which the certificate is valid, formatted as an RFC3339 date string. | `string` | `null` | no |

---

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_app_role_ids"></a> [app\_role\_ids](#output\_app\_role\_ids) | A mapping of app role values to app role IDs, intended to be useful when referencing app roles in other resources in your configuration. |
| <a name="output_application_id"></a> [application\_id](#output\_application\_id) | The Application ID (also called Client ID). |
| <a name="output_oauth2_permission_scope_ids"></a> [oauth2\_permission\_scope\_ids](#output\_oauth2\_permission\_scope\_ids) | A mapping of OAuth2.0 permission scope values to scope IDs, intended to be useful when referencing permission scopes in other resources in your configuration. |
| <a name="output_object_id"></a> [object\_id](#output\_object\_id) | The application's object ID. |
| <a name="output_publisher_domain"></a> [publisher\_domain](#output\_publisher\_domain) | The verified publisher domain for the application. |

---

## Conclusion

This Terraform configuration offers an efficient way to create and manage Azure AD Application Certificates, ensuring that applications can securely authenticate and operate within the Azure environment.