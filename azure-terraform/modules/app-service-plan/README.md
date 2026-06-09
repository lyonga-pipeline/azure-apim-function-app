# App Service Plan Module

This module manages the App Service plan as a standalone lifecycle boundary.

## What Is Better

| Area | Reviewed Configuration Pattern | Improved Module Pattern |
| --- | --- | --- |
| Plan ownership | Function App or Web App modules can create plans implicitly. | Plan creation is separate so multiple apps can share a plan intentionally. |
| Reuse | One-app-one-plan assumptions can increase cost and reduce flexibility. | The plan can be consumed by web apps, function apps, and pattern modules. |
| Sizing | Raw provider settings can be repeated across apps. | Uses a clear contract for OS type, SKU, worker count, elastic worker count, per-site scaling, and zone balancing. |

## Design Intent

Use this module when the service plan lifecycle should be managed separately from app deployment. This supports shared plans, phased plan upgrades, and independent scaling decisions.

Keep apps in `web-app` and `function-app`, and attach them to the plan by passing `service_plan_id`.

