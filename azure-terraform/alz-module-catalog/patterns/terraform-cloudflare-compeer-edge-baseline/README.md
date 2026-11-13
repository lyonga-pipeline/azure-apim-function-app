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

## 1 Configure the Edge Root

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

## 2 Supply Credentials and Synchronize Tokens

| Credential | Where it belongs |
|---|---|
| Cloudflare API token | Sensitive `CLOUDFLARE_API_TOKEN` on the edge/release job, with approved account/zone permissions |
| Tunnel creation secret | Sensitive `cloudflare_tunnel_secrets`, keyed `external_nonprod`; canonical base64 of securely generated 32 bytes |
| Tunnel runtime token | Dedicated Key Vault secret read by the connector identity; never the API token |

Apply the edge root with DNS empty. Obtain the tunnel ID from `tunnel_ids`,
then prepare a non-secret release inventory; add a separate prod entry/secret:

```json
[
  {
    "account_id": "REPLACE_WITH_ACCOUNT_ID",
    "tunnel_id": "REPLACE_FROM_TUNNEL_IDS_OUTPUT",
    "vault_uri": "https://REPLACE_WITH_VAULT.vault.azure.net",
    "secret_name": "cloudflare-nonprod-token",
    "minimum_replicas": 2
  }
]
```

From an approved release agent with Python 3, Cloudflare credentials and an
Azure CLI OIDC login, run the helper commands from this pattern directory.
Run Terraform applies from the owning deployment roots, not this directory.

```sh
python3 scripts/tunnel_release.py sync-token INVENTORY.json
```

The job copies the current token to Key Vault without printing it; it does not
rotate it. The vault must use RBAC and be reachable by the agent and VMs.
Initial synchronization precedes secret-scoped VM role assignment.
Terraform v4 state can contain tunnel credentials; `sensitive` does not encrypt
or remove them. Restrict state, plan downloads and agent logs.

## 3 Deploy and Verify Windows Connectors

In the existing connector root, populate the four Windows VM entries and each
`windows_bootstrap` entry with the approved release/hash, vault ID/URI, token
secret name and per-replica rollout revision. Pin the Windows image version;
provide sensitive admin/domain-join credentials and approved Windows AMA/DCR
inputs. The [connector README](../../implementations/platform-lz/workspaces/platform-cloudflare-connectors/README.md)
contains the exact inputs and hub-workspace output examples.

Use two replicas in different zones per tunnel. Each must reach every assigned
origin over the approved firewall path. Confirm outbound TCP/UDP 7844, DNS,
Key Vault and artifact/update dependencies. Bootstrap retrieves the token using
managed identity, verifies the binary hash, configures service recovery and
checks local readiness. That does not prove origin or application health.

```sh
python3 scripts/tunnel_release.py check-rollout PLAN.json
# Apply the reviewed connector plan, then:
python3 scripts/tunnel_release.py verify-replicas INVENTORY.json --timeout 300
```

Wire these helpers into CI/HCP approvals. `PLAN.json` contains sensitive data;
never commit or log it. Change only one existing replica per tunnel per stage,
verify it, then change its peer. The plan check rejects unsafe fleet updates
and Windows VM replacement; intentional replacements need a separate cutover.

## 4 Publish and Operate

After local connector/origin/TLS checks, add this under the tunnel's
`dns_records` and apply the edge root:

```hcl
dns_records = {
  pilot = { zone_id = "REPLACE_WITH_EXISTING_ZONE_ID", name = "pilot.example.com" }
}
```

It defaults to a proxied CNAME targeting that tunnel. DNS is created after
declared ingress/Access resources, but runtime readiness is a separate gate.
First publish the approved nonprod pilot and test allowed/denied users, JWTs,
machine authentication where used, direct-origin restrictions and replica
failure. Promote production only after acceptance. Confirm WAF/bot entitlements,
security-log export, alerts, certificate renewal and recovery ownership.
Managed WAF execution supports `action_parameters = { id = "APPROVED_RULESET_ID" }`;
advanced parameter schemas need another reviewed implementation/owner.

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
