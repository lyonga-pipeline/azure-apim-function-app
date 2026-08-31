# terraform-azurerm-test-availabilityset-sql

> **Reference composition / example — NOT a certified reusable module.**
> Do not `source` this from a pattern or a workload root. It exists to show how
> the lean resource modules assemble into an availability-set SQL cluster.

This directory wires together, in one config, an availability set, NICs, managed
data disks + attachments, Windows VMs, `azurerm_mssql_virtual_machine` and a
domain-join extension. For production use, compose the dedicated modules
(`network-interface`, `windows-vm`, `windows-mssql-vm`,
`windows-vm-domain-join`, ...) at the pattern layer instead.

## What was fixed during the hardening pass

- azurerm 4.x renames: `enable_ip_forwarding` → `ip_forwarding_enabled`,
  `enable_accelerated_networking` → `accelerated_networking_enabled`,
  `enable_automatic_updates` → `automatic_updates_enabled`.
- `versions.tf` standardised (`terraform >= 1.5, < 2.0`, `azurerm >= 4.42, < 5.0`).

It is kept `terraform validate`-clean but is intentionally **not** given a typed
public contract or a `terraform test` suite — it is a fixture, not a product.
