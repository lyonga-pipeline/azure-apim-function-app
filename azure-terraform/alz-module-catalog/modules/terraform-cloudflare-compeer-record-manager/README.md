# Cloudflare Record Manager

This resource is a configuration block that defines a DNS record on Cloudflare using Terraform.

---

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 0.13.1 |
| <a name="requirement_cloudflare"></a> [cloudflare](#requirement\_cloudflare) | 4.11.0 |

---

## Providers

| Name | Version |
|------|---------|
| <a name="provider_cloudflare"></a> [cloudflare](#provider\_cloudflare) | 4.11.0 |

---

## Resources

| Name | Type |
|------|------|
| [cloudflare_record.record](https://registry.terraform.io/providers/cloudflare/cloudflare/4.11.0/docs/resources/record) | resource |
| [azurerm_client_config.current](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/client_config) | data source |

### Resource Block

```hcl
resource "cloudflare_record" "record" {
  ...
}
```

This declares a resource of type `cloudflare_record` with a local name `record`.

### Dynamic Blocks

The `dynamic` blocks allow for more complex configurations based on input variables. This is especially useful when certain attributes might not be defined or if we might have multiple sets of values (like multiple data blocks for different DNS record types).

#### Dynamic Data Block

This block defines dynamic records, potentially multiple, based on certain DNS types that require special data fields.

- `algorithm`, `altitude`, `certificate`, etc.: These are various data fields associated with specific DNS record types, like DNSSEC or SRV records. 

```hcl
dynamic "data" {
  ...
}
```

#### Dynamic Timeouts Block

This block defines timeouts for creating and updating the record. 

- `create`: Time to wait for the record to be created.
- `update`: Time to wait for the record to be updated.

```hcl
dynamic "timeouts" {
  ...
}
```

### Conditional Assignments

Throughout the resource block, you'll see patterns like:

```hcl
ttl = var.ttl != null ? var.ttl : null
```

This is a ternary operation that checks if the variable `var.ttl` is not null. If it's not, it assigns its value to the `ttl` attribute. Otherwise, it assigns `null`.

---

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_name"></a> [name](#input\_name) | The name of the record. Modifying this attribute will force creation of a new resource. | `string` | n/a | yes |
| <a name="input_proxied"></a> [proxied](#input\_proxied) | Whether the record gets Cloudflare's origin protection. | `bool` | n/a | yes |
| <a name="input_type"></a> [type](#input\_type) | The type of the record. | `string` | n/a | yes |
| <a name="input_zone_id"></a> [zone\_id](#input\_zone\_id) | The zone identifier to target for the resource. Modifying this attribute will force creation of a new resource. | `string` | n/a | yes |
| <a name="input_allow_overwrite"></a> [allow\_overwrite](#input\_allow\_overwrite) | "Allow creation of this record in Terraform to overwrite an existing record,    if any. This does not affect the ability to update the record in Terraform    and does not prevent other resources within Terraform or manual changes    outside Terraform from overwriting this record.    This configuration is not recommended for most environments. Defaults to false." | `bool` | `false` | no |
| <a name="input_comment"></a> [comment](#input\_comment) | Comments or notes about the DNS record. This field has no effect on DNS responses. | `string` | `null` | no |
| <a name="input_create_timeout"></a> [create\_timeout](#input\_create\_timeout) | Time to wait for the record to be created. | `string` | `null` | no |
| <a name="input_data"></a> [data](#input\_data) | Map of attributes that constitute the record value. Conflicts with 'value' | `map(any)` | `null` | no |
| <a name="input_priority"></a> [priority](#input\_priority) | The priority of the record | `number` | `null` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Custom tags for DNS record | `set(string)` | `null` | no |
| <a name="input_ttl"></a> [ttl](#input\_ttl) | The TTL of the record. | `number` | `null` | no |
| <a name="input_update_timeout"></a> [update\_timeout](#input\_update\_timeout) | Time to wait for the record to be updated. | `string` | `null` | no |
| <a name="input_value"></a> [value](#input\_value) | The value of the record. Conflicts with 'data'. | `string` | `null` | no |

---

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_record_hostname"></a> [record\_hostname](#output\_record\_hostname) | The FQDN of the record. |
| <a name="output_record_metadata"></a> [record\_metadata](#output\_record\_metadata) | A key-value map of string metadata Cloudflare associates with the record. |
| <a name="output_record_resource_id"></a> [record\_resource\_id](#output\_record\_resource\_id) | The ID of this resource. |

---

### Conclusion

This Terraform configuration provides a flexible way to manage Cloudflare DNS records, covering various record types and their specific configurations.
