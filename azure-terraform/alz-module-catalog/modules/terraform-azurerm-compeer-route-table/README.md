# Route Table Module

This module manages route tables separately from subnet attachment.

## What Is Better

| Area | Reviewed Configuration Pattern | Improved Module Pattern |
| --- | --- | --- |
| Routing lifecycle | Route tables and subnet associations can be bundled into broad network modules. | Route table creation is separate from subnet association. |
| Ownership | Routing policy and subnet ownership may differ. | Route associations are explicit companion resources. |

## Design Intent

Use this module for route table creation and routes. Use `subnet-route-table-association` to attach the route table to a subnet.
