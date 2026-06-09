# Container Agent Module

This module creates Azure Container Instances for lightweight agent or runner workloads while keeping networking, identity, and secret inputs explicit.

## What Is Better

| Area | Reviewed Configuration Pattern | Improved Module Pattern |
| --- | --- | --- |
| Container contract | Container settings can be modeled as loose flat variables. | Containers are passed as a map of typed objects. |
| Networking | Private placement can be inconsistent. | Private IP mode and subnet IDs are explicit inputs. |
| Secrets | Environment variables and secret mounts can be mixed together. | Secure environment variables and volume secrets are modeled separately. |
| Registry auth | Private registry settings may be handled ad hoc. | Registry credentials are exposed as a dedicated map. |

## Design Intent

This module owns:

- Container group creation
- One or more container definitions
- Optional private subnet placement
- Optional identity
- Registry credentials
- Environment variables, secure variables, and volumes

Use companion modules for:

- `virtual-network`
- `network-security-group`
- `key-vault-secret`
- `role-assignments`
- `diagnostic-settings`

## Why This Matters

Agent workloads often need private networking and secret access, but they should not create or infer the surrounding platform. This module keeps the container workload reusable and predictable.

