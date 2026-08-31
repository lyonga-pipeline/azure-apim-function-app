# terraform-azuread-compeer-service-principal

A service principal (`azuread_service_principal`) for an existing application,
passed in by `client_id`. App-role assignments, federated credentials and
directory-group membership are companion concerns, not owned here.

## Usage

```hcl
module "sp" {
  source    = "../terraform-azuread-compeer-service-principal"
  client_id = module.app.client_id
  owners    = [data.azuread_client_config.current.object_id]
}
```

## Inputs (selected)

| Input | Type | Default | Notes |
|---|---|---|---|
| `client_id` | string | — | the application to create the SP for; ForceNew |
| `account_enabled` | bool | `null` | |
| `preferred_single_sign_on_mode` | string | `null` | validated oidc/password/saml/notSupported; `saml` requires `saml_single_sign_on` (precondition) |
| `feature_tags` | object | `null` | mutually exclusive with `tags` (precondition) |
| `tags` | set(string) | `[]` | |
| `owners` | set(string) | `null` | |

## Outputs

`id`, `object_id`, `client_id`.

## Lifecycle contract

All fields **update in place**. `client_id` is **ForceNew**. `object_id` /
`client_id` are stable — safe for role assignments.

State exposure: none.

## Migration

Fixed a `contains(list, null)` crash in the `preferred_single_sign_on_mode`
validation (now `== null ? true : …`). Added `id` output and descriptions.

## Tests

`terraform test` (offline, `mock_provider "azuread"`): create, saml-without-config
precondition.
