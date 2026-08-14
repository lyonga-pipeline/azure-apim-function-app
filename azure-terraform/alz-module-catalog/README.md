# Compeer ALZ Module Catalog

This directory is the working catalog for the next ALZ module set. It stages the modules and patterns that should be published or republished as individual HCP registry modules.

The catalog is platform-first:

- `modules/` contains reusable resource modules with one clear lifecycle boundary per Azure or Cloudflare resource family.
- `patterns/` contains opinionated compositions for platform landing-zone slices, such as management groups, connectivity, hybrid connectivity, workload spokes, Palo Alto hub security, and Cloudflare edge baseline.
- Existing platform roots under `../landing-zones/net-new-hub-spoke` remain the deployable reference implementation until these catalog modules are promoted.

## Platform Coverage

The catalog now includes the missing platform ALZ building blocks needed for Phase 1 and Phase 2 planning:

- Management group hierarchy and subscription placement
- Subscription vending
- Policy baseline assignment and exemptions
- Management locks
- Hub and spoke networking
- Private DNS zones, links, resolver, endpoints, and records
- ExpressRoute circuit, VPN/ER gateway, gateway connection, local network gateway, route server, and route tables
- NSGs, NAT gateways, public IPs, load balancers, DDoS plan, Azure Firewall, and firewall policy
- Bastion as an optional privileged access path
- Palo Alto hub pattern for VM-Series, NICs, bootstrap storage, and load balancers
- Log Analytics, diagnostic settings, action groups, metric alerts, Sentinel onboarding, storage immutability/lifecycle, and inactive Defender/SOC posture
- Identity modules for Azure AD groups, applications, service principals, user-assigned identities, custom roles, and RBAC assignments
- Cloudflare zone, records, ruleset, and edge-baseline pattern
- Workload-adjacent services required by the pilot, including Key Vault, storage, API Management, App Configuration, and Recovery Services Vault
- Operational contracts for required controls that remain cost-disabled or externally owned until the owning team approves deployment

Defender/SOC posture and Sentinel are intentionally disabled by default so the module interface is codified without creating billable resources until the platform owner enables them.

## Promotion Guidance

Before publishing a staged module to HCP:

1. Keep provider blocks out of reusable modules unless the module truly owns a distinct provider configuration.
2. Keep `for_each` keys non-sensitive and stable.
3. Prefer maps of objects for repeatable child resources.
4. Default to private network access, CMK-ready encryption, diagnostic hooks, managed identity, RBAC, enterprise tags, and policy-friendly outputs.
5. Avoid `ignore_changes` for security-sensitive properties unless the exception is documented in the module README.
6. Add examples for at least one production-like configuration and one minimal disabled/no-cost configuration where applicable.

See `MODULE_REVIEW.md` for the detailed module readiness review.
