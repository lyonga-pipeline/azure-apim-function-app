# terraform-azuread-compeer-ad-application

Azure AD (Entra) **application registration** only. Passwords and certificates are
managed by companion modules (`terraform-azuread-compeer-ad-application-certificate`)
so credential rotation has an independent lifecycle and never re-creates the
registration.

## Usage

```hcl
module "app" {
  source       = "../terraform-azuread-compeer-ad-application"
  display_name = "svc-orders-api"

  sign_in_audience = "AzureADMyOrg"
  owners           = [data.azuread_client_config.current.object_id]

  app_role = {
    reader = {
      id                   = "b1e3...uuid"
      allowed_member_types = ["Application"]
      description          = "Read access"
      display_name         = "Reader"
      value                = "Orders.Read"
    }
  }

  web = {
    redirect_uris  = ["https://orders.example.com/signin-oidc"]
    implicit_grant = { id_token_issuance_enabled = true }
  }
}
```

## Inputs (selected)

| Input | Type | Default | Notes |
|---|---|---|---|
| `display_name` | string | - | update in place |
| `sign_in_audience` | string | `null` | validated enum |
| `group_membership_claims` | set(string) | `[]` | validated enum |
| `api` | object \| null | `null` | single block; `oauth2_permission_scope` is a `map(object)` keyed by scope key |
| `app_role` | map(object) | `{}` | **keyed** by stable logical key; `allowed_member_types` validated |
| `required_resource_access` | map(object) | `{}` | keyed by target API |
| `public_client` / `single_page_application` / `web` | object \| null | `null` | single blocks |
| `optional_claims` | object | `{...}` | rendered only when non-empty |
| `owners` / `identifier_uris` / `tags` | list/set | `[]` | update in place |

## Outputs

`id`, `client_id`, `object_id`, `publisher_domain`, `app_role_ids`,
`oauth2_permission_scope_ids`.

## Lifecycle contract

Every field on `azuread_application` is **update in place** - the registration is
never re-created by this module. Adding / removing an `app_role` or
`required_resource_access` map key affects only that entry (stable keys).
`app_role` / `oauth2_permission_scope` `id`s must be stable UUIDs - changing an
`id` disables the old role and creates a new one.

**State exposure:** none (credentials live in the companion module and, ideally,
are provider-generated).

## Migration

Breaking (0 consumers, no shims): `api` and `public_client` `list(object)` ->
`object` (single block); `app_role` and `required_resource_access` `list` ->
`map` keyed by a stable key; `web.implicit_grant` -> optional (its `for_each`
condition treated an object as a bool, which fails at plan when `web` is set).
Added `sign_in_audience` and `app_role.allowed_member_types` validation. Removed
the dead `azuread_client_config` data source.

## Tests

`terraform test` (offline, `mock_provider "azuread"`): minimal registration,
keyed app roles + web block, `sign_in_audience` and member-type validation.
