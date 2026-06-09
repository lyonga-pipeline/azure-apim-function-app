# APIM Custom Domain Module

This module supports the Terraform 2.0 APIM pattern by isolating APIM hostname and certificate binding from the APIM service lifecycle.

## What Is Better

| Area | Reviewed Configuration Pattern | Improved Module Pattern |
| --- | --- | --- |
| Certificate lifecycle | Domains and certificates can be embedded in the APIM service module. | Hostname bindings are managed independently from service creation. |
| Endpoint coverage | Gateway, portal, management, developer portal, and SCM hostnames need different settings. | Each endpoint type is modeled with map-based inputs. |
| Key Vault integration | Certificate material can be handled inconsistently. | Key Vault certificate IDs and identity client IDs are explicit inputs. |

## Design Intent

This module owns:

- APIM gateway custom domains
- Developer portal custom domains
- Management endpoint custom domains
- Portal and SCM custom domains
- Key Vault certificate references

Use companion modules for:

- `apim-service`
- `key-vault-certificate`
- `role-assignments`
- `private-dns-a-record` when private resolution is required

## Why This Matters

Custom domains and certificates often change on a different cadence than the APIM service. This module keeps those changes visible, reviewable, and independently promotable.

