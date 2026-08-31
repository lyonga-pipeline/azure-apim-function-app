# terraform-azuread-compeer-ad-application-certificate

A certificate credential on an existing Entra ID application
(`azuread_application_certificate`).

## Contract

- `application_id` (preferred) is the resource ID of the application
  (`/applications/{object-id}`). `application_object_id` is accepted for
  backward compatibility and internally converted.
- Exactly one of the two must be set (enforced by a precondition).
- `value` (sensitive) is the certificate; `type`, `encoding`, `end_date` /
  `end_date_relative`, `start_date`, `key_id` are optional.

## Lifecycle

| Change | Effect |
|---|---|
| `end_date_relative` / `end_date` | Replace (new credential) |
| `value`, `type`, `encoding` | Replace |
| `application_id` | Replace |

## State exposure

The certificate `value` is stored in Terraform state. Outputs: `id`, `key_id`,
`application_id`.

## Migration

`application_object_id` -> **`application_id`**. The old input still works
(shimmed to `/applications/${application_object_id}`) but is deprecated; move
callers to pass the `azuread_application` resource ID directly.

## Tests

`terraform test` — create with `application_id`, and precondition failure when
neither ID is supplied.
