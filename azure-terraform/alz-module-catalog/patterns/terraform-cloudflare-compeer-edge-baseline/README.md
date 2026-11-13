# Cloudflare Tunnels and Zero Trust Automation

This pattern configures the Cloudflare side of Compeer's external-application
ingress. A **Tunnel** provides connectivity to private Azure origins;
**Access** decides who can use an application. The Windows connectors initiate
outbound connections, so they need no public inbound IP or tunnel listener.

```text
Client -> Cloudflare edge/Access -> Tunnel -> Hub connector -> Palo Alto -> private origin
```

## Ownership and Prerequisites

| Owner | What it configures |
|---|---|
| [Edge root](../../implementations/platform-lz/workspaces/platform-cloudflare-edge) | Tunnels, ingress, Access applications/policies and approved DNS/WAF resources |
| [Windows connector root](../../implementations/platform-lz/workspaces/platform-cloudflare-connectors/README.md) | Windows 2022 VMs, managed-identity token retrieval, cloudflared service and monitoring composition |
| Existing network, IAM and security owners | Hub subnet/routes, Panorama rules, private DNS resolution, IdP/groups, licenses and security-log export |

Before enabling, obtain actual account/zone IDs, the Zero Trust team slug,
approved IdP/Access group IDs, external hostnames, private HTTPS origins and
certificate trust. Existing zones can stay with their current owner: pass their
`zone_id`; do not recreate them. Internal/regulated apps are not published here.

The provider remains **Cloudflare v4**. Keep the lock file; v5 examples use
different schemas. See Cloudflare's [setup](https://developers.cloudflare.com/tunnel/get-started/)
and [Terraform guide](https://developers.cloudflare.com/tunnel/guides/terraform/).

## Configure the Edge Root

Put application configuration in the edge root's `cloudflare_edge` object,
not in this reusable pattern. Example for one nonprod application:

```hcl
cloudflare_edge = {
  enabled = true
  approved_public_applications = {
    "pilot.example.com" = {
      classification     = "external-apps"
      approval_reference = "REPLACE_WITH_APPROVED_CHANGE"
    }
  }
  tunnels = {
    external_nonprod = {
      account_id       = "REPLACE_WITH_CLOUDFLARE_ACCOUNT_ID"
      name             = "compeer-external-nonprod"
      access_team_name = "replace-with-zero-trust-team-slug"
      ingress_rules = [{
        hostname = "pilot.example.com"
        service  = "https://pilot.origin.internal:443"
        origin_request = {
          origin_server_name = "pilot.origin.internal"
          no_tls_verify      = false
        }
      }]
      access_applications = {
        pilot = {
          name = "Pilot nonprod", domain = "pilot.example.com"
          allowed_idps = ["REPLACE_WITH_CLOUDFLARE_IDP_ID"]
          session_duration = "8h"
        }
      }
      access_policies = {
        pilot_users = {
          name = "Approved pilot users", application_key = "pilot"
          decision = "allow", precedence = 1
          include = [{ group = ["REPLACE_WITH_CLOUDFLARE_ACCESS_GROUP_ID"] }]
        }
      }
      dns_records = {} # Publish after connector and origin readiness checks.
    }
  }
}
```

Replace the example hostname/origin and all placeholders. `group` means a
Cloudflare Access group, not an arbitrary Entra group ID. IAM configures the
mapping and required MFA/posture. The helper derives JWT audiences from the
actual Access application and enables connector-side validation automatically.
Unmatched ingress ends in `http_status:404`.

The deployable root enables enterprise checks: approved exact hostnames,
external-app classification, verified HTTPS and Access coverage. A customer app
using approved application-owned authentication instead needs
`external_authentication_reason` in its approved hostname entry. This is an
explicit security exception, not a recommendation to bypass authentication.

## Zero Trust Applications and Policies

An Access application identifies the protected hostname and its login/session
settings. An Access policy grants or denies access to that application. Neither
a tunnel nor a DNS record grants user authorization. WAF rules inspect requests;
they do not replace identity-based Access policies.

Use `application_key` to reference an application in the same tunnel map. Terraform
resolves its ID and JWT audience; engineers must not paste those generated IDs.
`application_id` is supported for an existing application, but enterprise ingress
coverage still requires the matching application declaration in this pattern.
Do not manage that application in two states: import it into its agreed owner.

| Setting | Meaning and review requirement |
|---|---|
| `allowed_idps` | Cloudflare identity-provider IDs, not Entra tenant IDs. Restrict to the approved corporate IdP. |
| `include` | Initial eligible identities; multiple selectors use OR logic. Use approved Access groups or explicit service tokens. |
| `require` | Additional mandatory conditions, such as approved device posture. Multiple requirements narrow access; check AND semantics. |
| `exclude` | Identities or conditions excluded from this policy; review all other policies too. |
| `precedence` | Explicit policy ordering. Use distinct values per application; do not rely on map iteration. |
| `decision` | `allow` for approved people; `non_identity` for service authentication. This enterprise root rejects `bypass`. |
| `session_duration` | Approved session lifetime, not a substitute for MFA or device posture. |

For example, replace the example `pilot_users` policy with the following to
require a previously configured posture check and exclude a suspended group:

```hcl
pilot_users = {
  name            = "Pilot users on compliant devices"
  application_key = "pilot"
  decision        = "allow"
  precedence      = 1
  include = [{ group = ["REPLACE_WITH_APPROVED_ACCESS_GROUP_ID"] }]
  require = [{ device_posture = ["REPLACE_WITH_POSTURE_CHECK_ID"] }]
  exclude = [{ group = ["REPLACE_WITH_SUSPENDED_ACCESS_GROUP_ID"] }]
}
```

For an API client, use a separate policy with `decision = "non_identity"` and
`include = [{ service_token = ["REPLACE_WITH_SERVICE_TOKEN_ID"] }]`. Obtain the
service token from its security owner and distribute its credentials securely.
Never replace it with `everyone` or `any_valid_service_token`. Test machine
authentication and connector-side JWT validation together before publication.

The pattern does **not** create the Zero Trust organization, IdP integration,
Access groups, posture checks, service-token credentials, WARP enrollment or
Gateway DNS/HTTP/network policies. Assign those to an IAM/security configuration
owner and pass their Cloudflare IDs here. A Tunnel/Access deployment is not a
complete enterprise-wide Zero Trust deployment. Confirm MFA/group claims with
IAM rather than assuming that `allowed_idps` enforces them.
See [Access policy semantics](https://developers.cloudflare.com/cloudflare-one/access-controls/policies/).

## Rulesets and WAF Configuration

Add `rulesets` alongside `tunnels` inside the root's `cloudflare_edge` object.
For an existing zone use `zone_id`; use `zone_key` only for a zone owned by this
root. Account-scoped rulesets use `account_id` and an appropriate account kind;
do not mix account and zone scopes in one definition.

```hcl
rulesets = {
  external_custom = {
    zone_id = "REPLACE_WITH_EXISTING_ZONE_ID"
    name    = "Compeer external application protections"
    kind    = "zone"
    phase   = "http_request_firewall_custom"
    rules = [{
      ref         = "pilot_block_nonstandard_ports"
      description = "Pilot accepts standard HTTPS only"
      expression  = "(http.host eq \"pilot.example.com\" and not cf.edge.server_port in {443})"
      action      = "block"
      enabled     = true
    }]
  }
  external_managed = {
    zone_id = "REPLACE_WITH_EXISTING_ZONE_ID"
    name    = "Compeer managed WAF deployment"
    kind    = "zone"
    phase   = "http_request_firewall_managed"
    rules = [{
      ref               = "pilot_managed_waf"
      description       = "Execute approved managed WAF for pilot"
      expression        = "(http.host eq \"pilot.example.com\")"
      action            = "execute"
      action_parameters = { id = "REPLACE_WITH_32_CHARACTER_RULESET_ID" }
      enabled           = true
    }]
  }
}
```

Replace the managed ruleset ID with an entitled ruleset returned by the account's
Cloudflare API/dashboard; the placeholder intentionally cannot pass validation.
The two examples use different phases. A phase entry point is shared zone/account
configuration, not one resource per application: designate one owner per scope
and phase, and merge approved app rules into its ordered list. Import existing
entry points with their complete rules before applying; a partial Terraform
definition can remove other teams' rules. Use stable map keys and rule `ref`
values, and review list ordering. See [ruleset ownership and phases](https://developers.cloudflare.com/ruleset-engine/about/rulesets/).

This adapter supports expressions/actions and only `action_parameters.id` for
managed-WAF `execute`. Rate-limit thresholds, skip parameters, managed-rule
overrides, transforms, cache settings and Logpush are **not implemented** here.
Do not paste those settings into `list(any)` and assume they are applied: extend
the typed adapter and tests or use a separately agreed owner. Verify plan/license
entitlements and inspect security events for false positives before promotion.
See [Cloudflare's WAF Terraform guide](https://developers.cloudflare.com/terraform/additional-configurations/waf-custom-rules/);
adapt its current-provider examples to this repository's pinned v4 schema.

## Credentials and State Protection

| Credential | Where it belongs |
|---|---|
| Cloudflare API token | Sensitive `CLOUDFLARE_API_TOKEN` on the edge/release job, with approved account/zone permissions |
| Tunnel creation secret | Sensitive `cloudflare_tunnel_secrets`, keyed `external_nonprod`; canonical base64 of securely generated 32 bytes |
| Tunnel runtime token | Dedicated Key Vault secret read by the connector identity; never the API token |

Scope the API token to the actual account/zones and operations: tunnel management,
Access applications/policies, DNS editing and WAF editing as used. Zone creation
needs additional rights only when this root owns zones. Validate endpoint-specific
permissions in the tenant; a token that edits DNS may not read tunnel tokens.
Keep prod credentials and approvals separate and rotate them through the approved
secret-management process. The runtime token authorizes a connector to join a
tunnel, not to manage the Cloudflare account. See [tunnel token security](https://developers.cloudflare.com/tunnel/reference/tunnel-tokens/).

Terraform v4 state can contain tunnel credentials; `sensitive` does not encrypt
or remove them. Restrict state, plan downloads and agent logs.

## Tunnel Configuration and Publication Sequence

`tunnels` map keys give stable Terraform ownership; one tunnel can serve several
approved hostnames. Add each hostname's ingress, Access application/policy and
DNS entry to the same tunnel definition. Ingress is an ordered list: specific
hostname/path rules precede broader matches. The helper appends terminal 404.
`config_src = "cloudflare"` means Terraform owns remote ingress configuration;
do not also maintain local ingress YAML or dashboard edits for that tunnel.

`service` is the private origin URL reached from the connector network.
`origin_server_name` selects the TLS certificate/SNI name;
`http_host_header`, when needed, selects the origin's HTTP virtual host. These
can differ from the public hostname. Keep certificate verification enabled and
have the origin/connector owners establish trust for private CAs. A successful
Terraform apply proves configuration acceptance, not private DNS, firewall
reachability or certificate trust.

1. Confirm tenant prerequisites, ownership and origin readiness. Import any
   existing objects into their single owner before applying.
2. Apply the edge root with ingress, Access and approved WAF rules, but with
   `dns_records = {}`. Supply secrets as sensitive workspace inputs.
3. Hand the tunnel ID and secure runtime-token delivery to the connector owner.
   VM deployment, bootstrap, token-sync commands and replica rollout belong in
   the [connector pattern guide](../terraform-azurerm-compeer-cloudflare-connectors/README.md),
   not this edge configuration. Require evidence of origin/TLS and replica health.
4. Add the DNS entry below and apply a newly reviewed edge plan. DNS depends on
   tunnel configuration and Access resources, **not** on live connector health or
   WAF readiness. Enforce those as release gates; Terraform dependencies alone
   cannot guarantee an outage-free publication.
5. Test allowed and denied identities, missing/invalid machine credentials,
   origin protection and WAF behavior. Promote prod through its own approval.

After local connector/origin/TLS checks, add this under the tunnel's
`dns_records` and apply the edge root:

```hcl
dns_records = {
  pilot = { zone_id = "REPLACE_WITH_EXISTING_ZONE_ID", name = "pilot.example.com" }
}
```

The target defaults to the created tunnel CNAME; no tunnel UUID or CNAME needs
copying into tfvars. Reuse existing zone IDs and fully qualified hostnames.
Before go-live assign owners for Access/WAF/tunnel alerts, security-log export,
certificate renewal, service-token expiry, incident access and recovery.

## Automation Risks and Preventive Controls

| Common issue | How to prevent or recover |
|---|---|
| Existing dashboard objects conflict or disappear | Inventory/import first; preserve complete rulesets, assign one state owner, and prohibit unreviewed dashboard writes. |
| Unauthorized API calls or wrong tenant | Preflight account/zone IDs, scoped token permissions and subscription entitlements using the deployment identity. Never solve failures with a global API key. |
| Current online examples fail validation | Pin v4 and commit lock files. Upgrade providers in a separate tested PR; do not mix v5 schemas into this module. |
| Access unexpectedly admits users or locks them out | Review include/require/exclude logic and all application policies, test real IdP claims and denied users, and avoid broad selectors/bypass. CI guards do not prove IAM intent. |
| DNS exposes an unready or unprotected origin | Separate configuration from DNS publication. Gate on Access tests, approved WAF configuration, live tunnel replicas and origin TLS/health. |
| WAF change breaks unrelated apps | One phase owner, hostname-scoped expressions, stable rule refs and full-list review. Test valid traffic plus known blocked cases before prod. |
| TLS failures tempt disabling verification | Correct SNI, origin Host header and certificate trust with the origin owner; keep `no_tls_verify = false`. |
| API throttling or propagation delay | Serialize runs for shared scope/state; use bounded retry/backoff for transient API errors and poll readiness. Do not bypass policy failures or repeatedly reapply blindly. |
| Renamed keys or removed map entries destroy objects | Treat map keys as persistent identifiers; inspect deletes/replacements and use reviewed moved/import operations. `enabled = false` plans removal of owned resources, not a harmless pause. |
| Secret leakage or failed rotation | Restrict state/plan artifacts and logs; never commit tokens. Coordinate rotation with the connector owner and verify healthy replicas before retiring credentials. Token synchronization is not rotation. |
| Console hotfix is reverted by Terraform | Record emergency changes, reconcile configuration/imports, then run a fresh plan. Avoid blanket `ignore_changes` on security policy. |

Run `fmt`, validation, mocked tests and a saved-plan review in CI. Apply only the
approved plan using a locked workspace; require security review for authentication,
WAF scope, publication and destructive changes. Follow apply with synthetic
authentication/origin checks and a fresh drift plan. Keep previous reviewed
configuration for rollback, but re-plan it: restoring Git alone does not restore
deleted objects or credentials. During an incident withdraw publication or restore
the reviewed policy; do not weaken Access/TLS as a shortcut.

## DNS Ownership and Upgrades

Zones exist only at the edge layer, not in the tunnel helper. Generic legacy
`records` and tunnel `dns_records` now use **one shared DNS resource implementation**
in the tunnel package's `modules/dns-records`. Their different output maps and
input keys remain unchanged. The enterprise root uses tunnel DNS only.
Use fully qualified names; duplicate zone/hostname entries are rejected.

Both callers include `moved` blocks from `cloudflare_record.record` to
`module.dns_records.cloudflare_record.record`. After upgrading, run
`terraform init` and review the plan: existing records should show address
moves, not deletion/recreation. Keep those blocks for older states; never let
another workspace own the same physical DNS record.

For verification, run `terraform validate` and `terraform test` in this pattern,
the tunnel helper and its DNS submodule (Terraform 1.11+ for migration tests).
Run the Python tests in `scripts`.
Mock tests validate code behavior, not live tenant permissions or production
readiness. Refer to [Cloudflare token operations](https://developers.cloudflare.com/tunnel/reference/tunnel-tokens/)
and [observability](https://developers.cloudflare.com/tunnel/observability/) for day-two procedures.
