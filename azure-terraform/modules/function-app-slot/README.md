# Function App Slot Module

This companion module manages Function App deployment slots separately from the base Function App.

## What Is Better

| Area | Reviewed Configuration Pattern | Improved Module Pattern |
| --- | --- | --- |
| Slot lifecycle | Slots can be embedded into the base app module. | Slots are managed separately so release strategy can evolve independently. |
| Deployment model | Not every Function App needs slots. | Workload roots add slots only for apps that require them. |

## Design Intent

Use this module when deployment slots are part of the release pattern. Keep the base app in `function-app`, and compose slots, sticky settings, diagnostics, and private endpoints as needed.

