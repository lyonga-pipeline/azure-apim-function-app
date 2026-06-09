# Resource Group Module

This module creates the resource group boundary that application and platform roots compose with reusable resource modules.

## What Is Better

| Area | Reviewed Configuration Pattern | Improved Module Pattern |
| --- | --- | --- |
| Boundary clarity | Resource groups can be created inline in application stacks. | Resource group ownership is explicit and reusable. |
| Tagging | Tags can vary across resources if not normalized. | The module accepts the merged enterprise tag map from `platform-tags`. |
| Composition | Application modules should not assume they own the resource group. | Roots pass `resource_group_name` into child modules. |

## Design Intent

This module owns:

- Resource group creation
- Location
- Tags

Use companion modules for:

- `platform-tags`
- All workload modules that deploy into the resource group

## Why This Matters

Resource groups are lifecycle and ownership boundaries. Keeping them explicit makes environment isolation, RBAC, tagging, and cleanup easier to reason about.

