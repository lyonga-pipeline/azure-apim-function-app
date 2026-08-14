# terraform-cloudflare-compeer-ruleset

Creates a Cloudflare ruleset at account or zone scope.

## Catalog Fixes

- `rules` is now a list, matching the module description and Cloudflare ruleset behavior.
- `matched_data.public_key` is read from the `matched_data` block rather than the sibling `headers` iterator.
- Cache key query-string exclusions are supported through `action_parameters.cache_key.custom_key.query_string.exclude`.

## Example

```hcl
module "managed_rules" {
  source = "./modules/terraform-cloudflare-compeer-ruleset"

  zone_id       = var.cloudflare_zone_id
  ruleset_kind  = "zone"
  ruleset_name  = "waf-baseline"
  ruleset_phase = "http_request_firewall_managed"

  rules = [
    {
      expression  = "true"
      action      = "execute"
      description = "Execute managed WAF baseline"
      action_parameters = {
        id = "efb7b8c949ac4650a09736fc376e9aee"
      }
    }
  ]
}
```
