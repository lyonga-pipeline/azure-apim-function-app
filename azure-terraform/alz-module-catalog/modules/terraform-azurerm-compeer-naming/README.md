# Compeer Azure Naming

Generates standard Azure names from root-level context and stable resource
keys. The module is provider-free: it creates no resources and owns no
lifecycle. Platform and workload patterns consume its outputs.

## Naming Model

The caller supplies two kinds of information:

1. Root identity: `region`, `environment`, `scope`, and either `component` or
   `domain`/`appcode`.
2. Resource identity: stable keys such as `audit`, `primary`, or `firewall`.

```text
root context + resource key -> generated Azure name
```

The root controls values through variables or tfvars. Patterns provide natural
component defaults such as `management`, `connectivity`, and `identity`.

## Platform Example

```hcl
module "naming" {
  source = "app.terraform.io/Compeer-Financial-Services/compeer-naming/azurerm"

  region      = var.location
  environment = var.environment
  scope       = "platform"
  component   = "management"

  key_vault_keys       = keys(var.key_vaults)
  storage_account_keys = keys(var.storage_accounts)
  storage_uniqueness   = var.subscription_id
}
```

Given these tfvars:

```hcl
storage_accounts = {
  audit       = {}
  diagnostics = {}
}
```

Consume the keyed output with the same stable key:

```hcl
name = module.naming.storage_account_names[each.key]
```

## Workload Example

```hcl
module "naming" {
  source = "app.terraform.io/Compeer-Financial-Services/compeer-naming/azurerm"

  region      = var.location
  environment = var.environment
  scope       = "workload"
  domain      = var.workload_domain
  appcode     = var.workload_appcode

  nsg_keys              = keys(var.network_security_groups)
  route_table_keys      = keys(var.route_tables)
  private_endpoint_keys = keys(var.private_endpoints)
}
```

`domain` identifies the workload area, while optional `appcode` provides the
application-specific prefix for constrained workload resources such as Key
Vault, storage accounts, identities, and Function Apps.

## Core Inputs

| Input | Purpose |
|---|---|
| `region` | Azure region long name; converted to the approved short code |
| `environment` | Environment token used in generated names |
| `scope` | `platform` or `workload` |
| `component` | Platform root discriminator, for example `management` |
| `domain` | Workload or governance domain, for example `internal-apps` |
| `appcode` | Optional workload application code, 1-9 letters |
| `abbreviation` | Optional approved 1-10 character short discriminator |
| `storage_uniqueness` | Stable seed for the storage-account uniqueness suffix |

Approved resource environments are `dev`, `test`, `uat`, `prod`, `sandbox`,
`np1`, `np2`, and `np3`, matching the tagging module. `shared` is additionally
allowed only for cross-environment names such as governance, policy,
authorization, and subscription-vending objects. The ambiguous legacy value
`np` is rejected.

## Keyed Resources

Pass the keys of each resource map once and consume the corresponding output:

| Input | Output |
|---|---|
| `key_vault_keys` | `key_vault_names` |
| `storage_account_keys` | `storage_account_names` |
| `user_assigned_identity_keys` | `user_assigned_identity_names` |
| `function_app_keys` | `function_app_names` |
| `nsg_keys` | `nsg_names` |
| `route_table_keys` | `route_table_names` |
| `public_ip_keys` | `public_ip_names` |
| `private_endpoint_keys` | `private_endpoint_names` |
| `network_interface_keys` | `network_interface_names` |
| `load_balancer_keys` | `load_balancer_names` |
| `virtual_machine_keys` | `virtual_machine_names` |
| `disk_keys` | `disk_names` |
| `recovery_services_vault_keys` | `recovery_services_vault_names` |
| `subnet_keys` | `subnet_names` |

Use meaningful stable keys, not positional indexes. Adding one key then creates
one additional name without changing existing resource identities.

Naming tokens use alphanumeric segments separated by single hyphens. Stable
resource keys may use hyphens or underscores; underscores are rendered as
hyphens in Azure names while the original key remains unchanged for `for_each`.
The module rejects unsupported characters and normalized name collisions.

## Explicit Overrides

Generated names are the standard path, but consuming patterns should allow an
explicit name to win for imports and approved exceptions:

```hcl
name = coalesce(
  try(each.value.name, null),
  module.naming.storage_account_names[each.key]
)
```

The naming module itself does not manage overrides because resource-specific
configuration belongs to the consuming pattern.

## Constrained and Global Names

Key Vault and storage-account names have tight length limits. The module uses:

1. An explicit `abbreviation`, when supplied.
2. The built-in approved abbreviation map.
3. A deterministic fallback derived from the discriminator.

Add an approved abbreviation when a new component or domain owns constrained
resources. Changing an abbreviation after deployment changes generated names
and can force resource replacement.

Storage-account names are globally unique. Supply a stable seed such as the
subscription ID:

```hcl
storage_uniqueness = var.subscription_id
```

The module hashes the seed to a stable four-character suffix and preserves the
suffix when truncating to Azure's 24-character limit. Do not use a changing or
random seed.

Function App names are also globally unique, but the module does not append a
hash. Use a distinctive stable resource key or an explicit approved name.

## Singular Outputs

The module also exposes context-generated singleton names, including resource
groups, hub/shared/workload VNets, gateways, monitoring resources, management
groups, subscriptions, policy objects, and Entra groups. Outputs whose required
tokens were not supplied return `null`.

Fixed organizational names, such as `platform-mg`, are intentionally separate
from keyed repeated-resource names.

## Compatibility Inputs

`purpose`, `destination`, and `resource` remain for existing singular callers.
New consumers should use the resource-specific `*_keys` inputs. These legacy
inputs will remain until a major release removes them after all consumers have
migrated.

Specialized firewall and domain-controller VM names still use `instance`
because their approved formats contain a zero-padded numeric instance. Their
current consumers therefore retain per-instance module calls.

## Validation and Lifecycle

The module validates region/environment vocabularies, token characters,
cross-input requirements, case-normalized collisions, and Azure length rules.
Changing an already-published naming formula can replace downstream Azure
resources. Treat such changes as breaking changes and publish a new major
module version with migration guidance.

## Extending the Module

When adding a resource type:

1. Confirm whether the naming standard already defines its format.
2. Use the closest approved resource pattern only when no explicit format
   exists, and document the adaptation.
3. Add a keyed input/output when a root may create multiple instances.
4. Add Azure-specific length and character validation.
5. Add tests for valid output, invalid tokens, limits, and stable keyed names.
6. Keep the resource lifecycle in its base module or consuming pattern.

## Testing

```shell
terraform test
```

Tests cover platform and workload context, region mapping, approved
environments, keyed resources, abbreviation overrides, collisions, invalid
tokens, storage uniqueness, and Azure length limits.
