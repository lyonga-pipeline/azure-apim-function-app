# Cloudflare Zone Manager

This module helps to creates and manages a domain zone in Cloudflare. The cloudflare_zone resource resource creates and handles the basic setup of a domain in Cloudflare. The cloudflare_zone_settings_override resource customizes and optimizes various settings of the previously created Cloudflare zone.

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
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | 3.69.0 |
| <a name="provider_cloudflare"></a> [cloudflare](#provider\_cloudflare) | 4.11.0 |

---

## Modules

No modules.

---

## Resources

| Name | Type |
|------|------|
| [cloudflare_zone.zone](https://registry.terraform.io/providers/cloudflare/cloudflare/4.11.0/docs/resources/zone) | resource |
| [cloudflare_zone_settings_override.zone_settings](https://registry.terraform.io/providers/cloudflare/cloudflare/4.11.0/docs/resources/zone_settings_override) | resource |
| [azurerm_client_config.current](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/client_config) | data source |

### 1. Cloudflare Zone Creation

#### Resource Block

```hcl
resource "cloudflare_zone" "zone" {
  ...
}
```

This declares a Terraform resource of type `cloudflare_zone` with the local name `zone`.

### 2. Cloudflare Zone Settings Override

#### Resource Block

```hcl
resource "cloudflare_zone_settings_override" "zone_settings" {
  ...
}
```

This resource block manages the settings for the Cloudflare zone you've created.

#### Dynamic Settings Block

The dynamic block within this resource allows for a comprehensive management of various settings related to the Cloudflare zone. It uses the `lookup` function to pull the respective value from `var.zone_settings` or sets it to `null` if not found.

Inside this block are settings such as:

- Security enhancements (`always_online`, `browser_check`, `security_level`, `waf`, etc.)
- Performance optimizations (`brotli`, `cache_level`, `mirage`, `polish`, etc.)
- Connection settings (`http2`, `http3`, `ipv6`, `ssl`, `tls_1_3`, etc.)
- ... and many more.

---

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_account_id"></a> [account\_id](#input\_account\_id) | Account ID to manage the zone resource in. | `string` | n/a | yes |
| <a name="input_zone"></a> [zone](#input\_zone) | The DNS zone name which will be added. Modifying this attribute will force creation of a new resource. | `string` | n/a | yes |
| <a name="input_zone_jump_start"></a> [zone\_jump\_start](#input\_zone\_jump\_start) | Whether to scan for DNS records on creation. Ignored after zone is created. | `bool` | `false` | no |
| <a name="input_zone_paused"></a> [zone\_paused](#input\_zone\_paused) | Whether this zone is paused (traffic bypasses Cloudflare). | `bool` | `false` | no |
| <a name="input_zone_plan"></a> [zone\_plan](#input\_zone\_plan) | The name of the commercial plan to apply to the zone. | `string` | `null` | no |
| <a name="input_zone_settings"></a> [zone\_settings](#input\_zone\_settings) | The Cloudflare Zone settings. | ```object({ always_online = optional(string) always_use_https = optional(string) automatic_https_rewrites = optional(string) binary_ast = optional(string) brotli = optional(string) browser_cache_ttl = optional(number) browser_check = optional(string) cache_level = optional(string) challenge_ttl = optional(number) ciphers = optional(string) cname_flattening = optional(string) development_mode = optional(string) early_hints = optional(string) email_obfuscation = optional(string) filter_logs_to_cloudflare = optional(string) h2_prioritization = optional(string) hotlink_protection = optional(string) http2 = optional(string) http3 = optional(string) image_resizing = optional(string) ip_geolocation = optional(string) ipv6 = optional(string) log_to_cloudflare = optional(string) max_upload = optional(string) min_tls_version = optional(string) mirage = optional(string) opportunistic_encryption = optional(string) opportunistic_onion = optional(string) orange_to_orange = optional(string) origin_error_page_pass_thru = optional(string) origin_max_http_version = optional(string) polish = optional(string) prefetch_preload = optional(string) privacy_pass = optional(string) proxy_read_timeout = optional(string) pseudo_ipv4 = optional(string) response_buffering = optional(string) rocket_loader = optional(string) security_level = optional(string) server_side_exclude = optional(string) sort_query_string_for_cache = optional(string) ssl = optional(string) tls_1_3 = optional(string) tls_client_auth = optional(string) true_client_ip_header = optional(string) universal_ssl = optional(string) visitor_ip = optional(string) waf = optional(string) webp = optional(string) websockets = optional(string) zero_rtt = optional(string) minify = optional(object({ css = string html = string js = string })) mobile_redirect = optional(object({ mobile_subdomain = string status = string strip_uri = bool })) security_header = optional(object({ enabled = optional(bool) include_subdomains = optional(bool) max_age = optional(number) nosniff = optional(bool) preload = optional(bool) })) })``` | `{}` | no |
| <a name="input_zone_type"></a> [zone\_type](#input\_zone\_type) | A full zone implies that DNS is hosted with Cloudflare. A partial zone is typically a partner-hosted zone or a CNAME setup. | `string` | `"full"` | no |

---

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_zone_id"></a> [zone\_id](#output\_zone\_id) | The ID of the resource |

---

## Conclusion

This Terraform configuration provides a comprehensive and modular approach to manage Cloudflare Zones and their settings. It ensures optimal performance, security, and reliability by taking full advantage of Cloudflare's features for a domain.
