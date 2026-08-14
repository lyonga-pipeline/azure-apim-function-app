# Azure Key Vault Assets Manager

This resource is a configuration block that creates or manages a secret within an Azure Key Vault.

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.2 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | >=3.11, < 4.0 |

---

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | 3.67.0 |

---

## Resources

| Name | Type |
|------|------|
| [azurerm_key_vault_certificate.generate_certificate](https://registry.terraform.io/providers/hashicorp/azurerm/3.67.0/docs/resources/key_vault_certificate) | resource |
| [azurerm_key_vault_certificate.import_certificate](https://registry.terraform.io/providers/hashicorp/azurerm/3.67.0/docs/resources/key_vault_certificate) | resource |
| [azurerm_key_vault_key.key](https://registry.terraform.io/providers/hashicorp/azurerm/3.67.0/docs/resources/key_vault_key) | resource |
| [azurerm_key_vault_secret.secret](https://registry.terraform.io/providers/hashicorp/azurerm/3.67.0/docs/resources/key_vault_secret) | resource |
| [azurerm_client_config.current](https://registry.terraform.io/providers/hashicorp/azurerm/3.67.0/docs/data-sources/client_config) | data source |

### 1. Azure Key Vault Secret Manager

This resource is a configuration block that creates or manages a secret within an Azure Key Vault.

#### Resource Block

```hcl
resource "azurerm_key_vault_secret" "secret" {
  ...
}
```

This declares a resource of type `azurerm_key_vault_secret` with a local name `secret`.

---

### 2. Azure Key Vault Key Manager

This resource block defines a cryptographic key within an Azure Key Vault.

#### Resource Block

```hcl
resource "azurerm_key_vault_key" "key" {
  ...
}
```

---

### 3. Azure Key Vault Import Certificate Manager

This resource allows for the importation of an existing certificate into an Azure Key Vault.

#### Resource Block

```hcl
resource "azurerm_key_vault_certificate" "import_certificate" {
  ...
}
```

### 4. Azure Key Vault Generate Certificate Manager

This resource generates a new certificate within an Azure Key Vault.

#### Resource Block

```hcl
resource "azurerm_key_vault_certificate" "generate_certificate" {
  ...
}
```

---

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_key_vault_id"></a> [key\_vault\_id](#input\_key\_vault\_id) | "(Required) The ID of the Key Vault where the Secret should be created.   Changing this forces a new resource to be created." | `string` | n/a | yes |
| <a name="input_secret_name"></a> [secret\_name](#input\_secret\_name) | "(Required) Specifies the name of the Key Vault Secret.   Changing this forces a new resource to be created." | `string` | `null` | no |
| <a name="input_certificate_name"></a> [certificate\_name](#input\_certificate\_name) | "(Required) Specifies the name of the Key Vault Certificate.   Changing this forces a new resource to be created." | `string` | `null` | no |
| <a name="input_certificate_policy"></a> [certificate\_policy](#input\_certificate\_policy) | A certificate\_policy block. Changing this forces a new resource to be created. Refer to [`certificate_policy` Block Details](#certificate_policy-block-details) for details. | ```object({ issuer_parameters = object({ name = string }) key_properties = object({ curve = optional(string) exportable = bool key_type = string key_size = optional(number) reuse_key = bool }) lifetime_action = optional(list(object({ action = object({ action_type = string }) trigger = object({ lifetime_percentage = optional(number) days_before_expiry = optional(number) }) }))) secret_properties = object({ content_type = string }) x509_certificate_properties = optional(object({ extended_key_usage = optional(list(string)) key_usage = list(string) subject = string subject_alternative_names = optional(object({ dns_names = optional(list(string)) emails = optional(list(string)) upns = optional(list(string)) })) validity_in_months = number })) })``` | ```{ "issuer_parameters": { "name": "value" }, "key_properties": { "curve": "value", "exportable": false, "key_type": "value", "reuse_key": false }, "lifetime_action": [ { "action": { "action_type": "value" }, "trigger": { "days_before_expiry": 1, "lifetime_percentage": 1 } } ], "secret_properties": { "content_type": "value" }, "x509_certificate_properties": { "key_usage": [ "value" ], "subject": "value", "validity_in_months": 3 } }``` | no |
| <a name="input_certificate_tags"></a> [certificate\_tags](#input\_certificate\_tags) | A mapping of tags to assign to the resource. | `map(string)` | `{}` | no |
| <a name="input_create_key"></a> [create\_key](#input\_create\_key) | Whether to create a key | `bool` | `false` | no |
| <a name="input_create_secret"></a> [create\_secret](#input\_create\_secret) | Whether to create a secret | `bool` | `false` | no |
| <a name="input_generate_certificate"></a> [generate\_certificate](#input\_generate\_certificate) | Whether to generate a new certificate | `bool` | `false` | no |
| <a name="input_import_certificate"></a> [import\_certificate](#input\_import\_certificate) | Whether to import an existing certificate | `bool` | `false` | no |
| <a name="input_import_certificate_block"></a> [import\_certificate\_block](#input\_import\_certificate\_block) | A certificate block as defined below, used to Import an existing certificate. Refer to [`import_certificate_block` Block Details](#import_certificate_block-block-details) for details. | ```object({ contents = string password = string # Add other attributes as needed })``` | `null` | no |
| <a name="input_import_certificate_name"></a> [import\_certificate\_name](#input\_import\_certificate\_name) | "(Required) Specifies the name of the Key Vault Certificate.   Changing this forces a new resource to be created." | `string` | `null` | no |
| <a name="input_import_certificate_tags"></a> [import\_certificate\_tags](#input\_import\_certificate\_tags) | A mapping of tags to assign to the resource. | `map(string)` | ```{ "name": "value" }``` | no |
| <a name="input_key_curve"></a> [key\_curve](#input\_key\_curve) | "Specifies the curve to use when creating an EC key.   Possible values are P-256, P-256K, P-384, and P-521.   This field will be required in a future release if key\_type is EC or EC-HSM.   The API will default to P-256 if nothing is specified.   Changing this forces a new resource to be created." | `string` | `"value"` | no |
| <a name="input_key_expiration_date"></a> [key\_expiration\_date](#input\_key\_expiration\_date) | Expiration UTC datetime (Y-m-d'T'H:M:S'Z'). | `string` | `"value"` | no |
| <a name="input_key_name"></a> [key\_name](#input\_key\_name) | "(Required) Specifies the name of the Key Vault Key.    Changing this forces a new resource to be created." | `string` | `null` | no |
| <a name="input_key_not_before_date"></a> [key\_not\_before\_date](#input\_key\_not\_before\_date) | Key not usable before the provided UTC datetime (Y-m-d'T'H:M:S'Z'). | `string` | `"value"` | no |
| <a name="input_key_opts"></a> [key\_opts](#input\_key\_opts) | (Required) A list of JSON web key operations.   Possible values include: decrypt, encrypt, sign, unwrapKey, verify and wrapKey.   Please note these values are case sensitive. | `list(string)` | `null` | no |
| <a name="input_key_rotation_policy"></a> [key\_rotation\_policy](#input\_key\_rotation\_policy) | The rotation policy settings for the Key Vault Key. Refer to [key_rotation_policy Block](#key_rotation_policy-block) for details. | ```object({ expire_after = string notify_before_expiry = string automatic_rotation = object({ enabled = bool time_after_creation = string time_before_expiry = string }) })``` | `null` | no |
| <a name="input_key_size"></a> [key\_size](#input\_key\_size) | description = "Specifies the Size of the RSA key to create in bytes.   For example, 1024 or 2048. Note: This field is required if key\_type is RSA or RSA-HSM.   Changing this forces a new resource to be created." | `number` | `null` | no |
| <a name="input_key_tags"></a> [key\_tags](#input\_key\_tags) | A mapping of tags to assign to the resource. | `map(string)` | ```{ "name": "value" }``` | no |
| <a name="input_key_type"></a> [key\_type](#input\_key\_type) | "(Required) Specifies the Key Type to use for this Key Vault Key.   Possible values are EC (Elliptic Curve), EC-HSM, RSA and RSA-HSM.   Changing this forces a new resource to be created." | `string` | `null` | no |
| <a name="input_secret_content_type"></a> [secret\_content\_type](#input\_secret\_content\_type) | Specifies the content type for the Key Vault Secret. | `string` | `null` | no |
| <a name="input_secret_expiration_date"></a> [secret\_expiration\_date](#input\_secret\_expiration\_date) | Expiration UTC datetime (Y-m-d'T'H:M:S'Z'). | `string` | `null` | no |
| <a name="input_secret_not_before_date"></a> [secret\_not\_before\_date](#input\_secret\_not\_before\_date) | Key not usable before the provided UTC datetime (Y-m-d'T'H:M:S'Z'). | `string` | `null` | no |
| <a name="input_secret_tags"></a> [secret\_tags](#input\_secret\_tags) | A mapping of tags to assign to the resource. | `map(string)` | `null` | no |
| <a name="input_secret_value"></a> [secret\_value](#input\_secret\_value) | (Required) Specifies the value of the Key Vault Secret. | `string` | `null` | no |

### `key_rotation_policy` Block

This block supports:

- **expire_after**: *(Optional)* Expire a Key Vault Key after a given duration specified as an ISO 8601 duration.
  
- **automatic**: *(Optional)* An `automatic` block as defined below.

- **notify_before_expiry**: *(Optional)* Notify at a given duration before expiry specified as an ISO 8601 duration. The default is `P30D`.

  #### `automatic` Block

  This block supports:

  - **time_after_creation**: *(Optional)* Rotate automatically at a duration after creation specified as an ISO 8601 duration.

  - **time_before_expiry**: *(Optional)* Rotate automatically at a duration before expiry specified as an ISO 8601 duration.

---

### `import_certificate_block` Block Details

The `import_certificate_block` block supports the following properties:

- **contents** (Required): The base64-encoded certificate contents.
  
- **password** (Optional): The password associated with the certificate.

```
Note

A PEM certificate is already base64 encoded. To successfully import, the `contents` property should include a PEM encoded X509 certificate and a `private_key` in `pkcs8` format. There should only be Linux-style `\n` line endings, and the entire block should have the PEM begin/end blocks around both the certificate data and the private key data.
```

To convert a private key to `pkcs8` format with OpenSSL, use the following command:

```
openssl pkcs8 -topk8 -nocrypt -in private_key.pem > private_key_pk8.pem
```

The PEM content should look something like:

```
-----BEGIN CERTIFICATE-----
aGVsbG8KaGVsbG8KaGVsbG8KaGVsbG8KaGVsbG8KaGVsbG8KaGVsbG8KaGVsbG8K
:
aGVsbG8KaGVsbG8KaGVsbG8KaGVsbG8KaGVsbG8KaGVsbG8KaGVsbG8KaGVsbG8K
-----END CERTIFICATE-----
-----BEGIN PRIVATE KEY-----
d29ybGQKd29ybGQKd29ybGQKd29ybGQKd29ybGQKd29ybGQKd29ybGQKd29ybGQK
:
d29ybGQKd29ybGQKd29ybGQKd29ybGQKd29ybGQKd29ybGQKd29ybGQKd29ybGQK
-----END PRIVATE KEY-----
```

---

### `certificate_policy` Block Details

This block supports:

- **issuer_parameters**: *(Required)* A `issuer_parameters` block as defined below.
- **key_properties**: *(Required)* A `key_properties` block as defined below.
- **lifetime_action**: *(Optional)* A `lifetime_action` block as defined below.
- **secret_properties**: *(Required)* A `secret_properties` block as defined below.
- **x509_certificate_properties**: *(Optional)* A `x509_certificate_properties` block as defined below. Required when certificate block is not specified.

#### `issuer_parameters` Block

This block supports:

- **name**: *(Required)* The name of the Certificate Issuer. Possible values include `Self` (for self-signed certificate), or `Unknown` (for a certificate issuing authority like Let's Encrypt and Azure direct supported ones). Changing this forces a new resource to be created.

#### `key_properties` Block

This block supports:

- **curve**: *(Optional)* Specifies the curve to use when creating an EC key. Possible values are P-256, P-256K, P-384, and P-521. This field will be required in a future release if key_type is EC or EC-HSM. Changing this forces a new resource to be created.
- **exportable**: *(Required)* Is this certificate exportable? Changing this forces a new resource to be created.
- **key_size**: *(Optional)* The size of the key used in the certificate. Possible values include 2048, 3072, and 4096 for RSA keys, or 256, 384, and 521 for EC keys. This property is required when using RSA keys. Changing this forces a new resource to be created.
- **key_type**: *(Required)* Specifies the type of key. Possible values are EC, EC-HSM, RSA, RSA-HSM, and oct. Changing this forces a new resource to be created.
- **reuse_key**: *(Required)* Is the key reusable? Changing this forces a new resource to be created.

#### `lifetime_action` Block

This block supports:

- **action**: *(Required)* An `action` block as defined below.
- **trigger**: *(Required)* A `trigger` block as defined below.

  ##### `action` Block

  This block supports:

  - **action_type**: *(Required)* The Type of action to be performed when the lifetime trigger is triggered. Possible values include `AutoRenew` and `EmailContacts`. Changing this forces a new resource to be created.

  ##### `trigger` Block

  This block supports:

  - **days_before_expiry**: *(Optional)* The number of days before the Certificate  expires that the action associated with this Trigger should run. Changing this   forces a new resource to be created. Conflicts with `lifetime_percentage`.
  - **lifetime_percentage**: *(Optional)* The percentage at which during the  Certificates Lifetime the action associated with this Trigger should run. Changing   this forces a new resource to be created. Conflicts with `days_before_expiry`.

#### `secret_properties` Block

This block supports:

- **content_type**: *(Required)* The Content-Type of the Certificate, such as `application/x-pkcs12` for a PFX or `application/x-pem-file` for a PEM. Changing this forces a new resource to be created.

#### `x509_certificate_properties` Block

This block supports:

- **extended_key_usage**: *(Optional)* A list of Extended/Enhanced Key Usages. Changing this forces a new resource to be created.
- **key_usage**: *(Required)* A list of uses associated with this Key. Possible values include `cRLSign`, `dataEncipherment`, `decipherOnly`, `digitalSignature`, `encipherOnly`, `keyAgreement`, `keyCertSign`, `keyEncipherment` and `nonRepudiation` and are case-sensitive. Changing this forces a new resource to be created.
- **subject**: *(Required)* The Certificate's Subject. Changing this forces a new resource to be created.
- **subject_alternative_names**: *(Optional)* A `subject_alternative_names` block as defined below. Changing this forces a new resource to be created.
- **validity_in_months**: *(Required)* The Certificates Validity Period in Months. Changing this forces a new resource to be created.

  ##### `subject_alternative_names` Block

  This block supports:

  - **dns_names**: *(Optional)* A list of alternative DNS names (FQDNs) identified by   the Certificate. Changing this forces a new resource to be created.
  - **emails**: *(Optional)* A list of email addresses identified by this   Certificate. Changing this forces a new resource to be created.
  - **upns**: *(Optional)* A list of User Principal Names identified by the   Certificate. Changing this forces a new resource to be created.

---

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_azurerm_key_vault_certificate_id"></a> [azurerm\_key\_vault\_certificate\_id](#output\_azurerm\_key\_vault\_certificate\_id) | The Key Vault Certificate ID. |
| <a name="output_azurerm_key_vault_certificate_secret_id"></a> [azurerm\_key\_vault\_certificate\_secret\_id](#output\_azurerm\_key\_vault\_certificate\_secret\_id) | The ID of the associated Key Vault Secret. |
| <a name="output_azurerm_key_vault_certificate_version"></a> [azurerm\_key\_vault\_certificate\_version](#output\_azurerm\_key\_vault\_certificate\_version) | The current version of the Key Vault Certificate. |
| <a name="output_azurerm_key_vault_certificate_versionless_id"></a> [azurerm\_key\_vault\_certificate\_versionless\_id](#output\_azurerm\_key\_vault\_certificate\_versionless\_id) | The Base ID of the Key Vault Certificate. |
| <a name="output_azurerm_key_vault_certificate_versionless_secret_id"></a> [azurerm\_key\_vault\_certificate\_versionless\_secret\_id](#output\_azurerm\_key\_vault\_certificate\_versionless\_secret\_id) | The Base ID of the Key Vault Secret. |
| <a name="output_azurerm_key_vault_key_id"></a> [azurerm\_key\_vault\_key\_id](#output\_azurerm\_key\_vault\_key\_id) | The ID of the Key Vault Key. |
| <a name="output_azurerm_key_vault_key_resource_id"></a> [azurerm\_key\_vault\_key\_resource\_id](#output\_azurerm\_key\_vault\_key\_resource\_id) | The (Versioned) ID for this Key Vault Key. This property points to a specific version of a Key Vault Key, as such using this won't auto-rotate values if used in other Azure Services. |
| <a name="output_azurerm_key_vault_key_resource_versionless_id"></a> [azurerm\_key\_vault\_key\_resource\_versionless\_id](#output\_azurerm\_key\_vault\_key\_resource\_versionless\_id) | The Versionless ID of the Key Vault Key. This property allows other Azure Services (that support it) to auto-rotate their value when the Key Vault Key is updated. |
| <a name="output_azurerm_key_vault_key_version"></a> [azurerm\_key\_vault\_key\_version](#output\_azurerm\_key\_vault\_key\_version) | The current version of the Key Vault Key. |
| <a name="output_azurerm_key_vault_key_versionless_id"></a> [azurerm\_key\_vault\_key\_versionless\_id](#output\_azurerm\_key\_vault\_key\_versionless\_id) | The Base ID of the Key Vault Key. |
| <a name="output_azurerm_key_vault_secret_id"></a> [azurerm\_key\_vault\_secret\_id](#output\_azurerm\_key\_vault\_secret\_id) | The ID of the Key Vault secret. |
| <a name="output_azurerm_key_vault_secret_version"></a> [azurerm\_key\_vault\_secret\_version](#output\_azurerm\_key\_vault\_secret\_version) | The current version of the Key Vault Secret. |

---

### Conclusion

This Terraform configuration provides a comprehensive approach to managing secrets, keys, and certificates within Azure Key Vault. It offers flexibility and a high degree of customization for various security and operational needs.
