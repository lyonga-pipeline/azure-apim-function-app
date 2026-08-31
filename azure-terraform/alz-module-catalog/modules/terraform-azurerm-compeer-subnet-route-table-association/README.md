# terraform-azurerm-compeer-subnet-route-table-association

Associates one route table to one subnet (`azurerm_subnet_route_table_association`).
Both IDs are caller-supplied. Kept as a single-association module (not `for_each`
over subnets) so removing one subnet's association never re-indexes unrelated
ones — compose with `for_each` at the pattern layer.

## Inputs

| Input | Type | Notes |
|---|---|---|
| `subnet_id` | string | ForceNew |
| `route_table_id` | string | update in place |

## Outputs

`id`.

## Lifecycle contract

`route_table_id` change → update in place; `subnet_id` change → replace. Only one
route table per subnet.

State exposure: none.

## Tests

`terraform test` (offline): create.
