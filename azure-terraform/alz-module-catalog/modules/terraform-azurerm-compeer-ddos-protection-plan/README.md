# terraform-azurerm-compeer-ddos-protection-plan

A single Azure DDoS Network Protection plan
(`azurerm_network_ddos_protection_plan`). VNets associate to it by ID via the
`virtual-network` / `networking` modules' `ddos_protection_plan_id` input — this
module does not own those associations.

## Inputs

| Input | Type | Default | Notes |
|---|---|---|---|
| `name` / `resource_group_name` / `location` | string | — | all ForceNew |
| `tags` | map(string) | `{}` | update in place |

## Outputs

`id`, `name`.

## Lifecycle contract

`tags` update in place; everything else is ForceNew. A DDoS plan is a durable,
billed resource — do not let routine module upgrades recreate it.

State exposure: none.

## Tests

`terraform test` (offline): create.
