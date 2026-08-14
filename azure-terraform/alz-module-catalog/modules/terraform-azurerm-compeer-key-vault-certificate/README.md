# Key Vault Certificate Module

This companion module manages Key Vault certificates separately from the Key Vault resource.

## What Is Better

| Area | Reviewed Configuration Pattern | Improved Module Pattern |
| --- | --- | --- |
| Certificate lifecycle | Certificate lifecycle can be hidden inside the vault module. | Certificates are managed as separate data-plane objects. |
| Ownership | Platform vault ownership and app certificate ownership can become mixed. | Workload roots can manage only the certificates they own. |
| Reuse | Different apps and domains need different certificate policies. | Certificate configuration is composed only where needed. |

## Design Intent

Use this module for certificates that belong to application or platform workloads. Use `app-service-certificate-binding`, `app-service-custom-hostname-binding`, or APIM/App Gateway companion modules for service-specific certificate attachment.

