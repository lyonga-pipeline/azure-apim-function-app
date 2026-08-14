# Application Gateway Module

This module is the Terraform 2.0 replacement pattern for the reviewed Application Gateway configuration. It keeps the Application Gateway resource complete for real routing scenarios while improving the interface shape and lifecycle clarity.

## What Is Better

| Area | Reviewed Configuration Pattern | Improved Module Pattern |
| --- | --- | --- |
| Interface shape | Large list-heavy nested inputs can create noisy plans and difficult consumption. | Uses stable map-based inputs for repeated named gateway components. |
| Feature coverage | Broad routing, listener, certificate, WAF, redirect, and URL path features are needed. | Keeps rich gateway feature coverage while making each named component explicit. |
| Drift handling | Reviewed pattern used `ignore_changes` for tags and diagnostic destination behavior. | Gateway contract avoids hiding drift by default; diagnostics are a companion module. |
| Secret posture | Certificate patterns can mix raw values and Key Vault references. | Supports Key Vault-oriented certificate patterns while leaving secret ownership outside the gateway module. |
| Lifecycle separation | Gateway, public IP, diagnostics, RBAC, and certificates can become tangled. | Gateway owns the gateway resource; public IPs, diagnostics, RBAC, and secret material can be composed separately. |

## Design Intent

This module owns:

- Application Gateway resource
- SKU and autoscale configuration
- Gateway IP configurations
- Frontend ports and frontend IP configuration references
- Backend pools and HTTP settings
- Probes, listeners, routing rules, redirects, rewrite rules, URL path maps
- SSL policy, trusted certificates, and WAF configuration
- Managed identity attachment

Use companion modules for:

- `public-ip`
- `key-vault-certificate`
- `role-assignments`
- `diagnostic-settings`
- `monitor-metric-alert`
- `private-dns-zone` and DNS record modules where required

## Why This Matters

Application Gateway has many inseparable nested blocks because Azure models routing inside the gateway resource. The improvement is not to split every nested block into separate Terraform modules, but to make the interface stable, named, validated, and easier to consume through approved gateway patterns.

