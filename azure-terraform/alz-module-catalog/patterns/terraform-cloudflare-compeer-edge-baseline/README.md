# Compeer Cloudflare Edge and Tunnel Standard

## Status and Design Review

Reviewed November 12, 2026 against **Azure Landing Zone Architecture & Design Document v13 - naming update**, section **8.6**, and **Azure Resource Deployment in New Landing Zone_v2**, sections **Cloudflare Tunnel VMs** and the Cloudflare-agent subnet/route-table definitions.

**Windows Server 2022 Datacenter Gen2 and managed bootstrap are implemented.** This OS is the user's approved choice in place of the document's Windows 2025 draft. The Compeer root explicitly selects Windows; legacy Linux consumers retain their resource addresses. Production readiness still requires real tenant inputs and live nonprod acceptance: local tests cannot certify Azure/Cloudflare permissions, firewall paths or Windows service behavior.

This README separates implemented capabilities, document requirements, and engineering recommendations. Recommendations are not additional requirements attributed to Dan's document.

| Requirement | Current implementation | Remaining production gate |
|---|---|---|
| Central external-application ingress (architecture 8.6) | Separate Cloudflare edge and Azure connector patterns | Approved application inventory and deployment ownership |
| No public publication of internal/regulated applications | Root enforces reviewed external-app classification | PR approval must verify classification against the actual application inventory |
| Named tunnels and remote ingress | Implemented, terminal 404 by default | Review hostnames, paths, origins and ordering |
| DNS and Access | Root requires Access coverage or explicit alternative-auth approval | Live positive/negative authorization tests |
| Four connectors: two nonprod, two prod | Windows inventory populated, disabled until configured | Confirm hubs/IP reservations and fill runtime/monitoring references |
| Windows VM profile | Windows 2022 Gen2, secure boot/vTPM, managed boot diagnostics and OS patching | Pin approved image; confirm Hybrid Benefit entitlement before setting license_type |
| Install, service recovery, token retrieval | Managed Run Command, checksum-pinned binary, secret-scoped managed identity, startup refresh and local readiness | Nonprod service/reboot/rotation tests |
| Firewall-inspected connector-to-origin path | Owned outside this pattern | Verify UDRs, return paths, NSGs and Panorama rules |
| WAF/bot protection and security logging | Managed-WAF execute ID now supported; Windows AMA ownership supported | Supply approved rulesets/entitlements and DCR/export configuration |
| Availability and operations | Not proven by Terraform mocks | Failover, monitoring, rotation and recovery evidence |

The adapter supports `action_parameters = { id = "APPROVED_MANAGED_RULESET_ID" }` for managed-WAF execute rules, including existing zone IDs. It deliberately rejects other action-parameter schemas rather than silently ignoring them. Advanced overrides/rate-limit schemas need their own reviewed extension or existing owner. Never assign one resource to multiple states. No WAF IDs, bot settings or licensing are guessed.

## Architecture and Ownership

```text
External client
  -> Cloudflare DNS / edge security / Access where required
  -> named Tunnel
  -> central Hub cloudflared replicas
  -> firewall-inspected private path
  -> approved external-application origin
```

Connectors initiate outbound sessions; they do not require a public inbound tunnel listener. This does not permit unrestricted connector-to-origin traffic. Architecture section 8.6 retains inspection/default-deny and excludes internal/regulated apps from publication.

| Owner / workspace | Responsibility |
|---|---|
| `platform-cloudflare-edge` | Cloudflare tunnels, remote ingress, declared DNS, Access and supported rulesets |
| `platform-cloudflare-connectors` | Azure VM/NIC infrastructure and explicitly supplied extensions/monitoring |
| Connectivity workspace | Hub subnet, NSG/UDR ownership and Hub routes |
| Network/firewall team | Panorama policy, egress approval and path validation |
| IAM/security | Zero Trust organization, IdP, groups, authentication and audit requirements |
| Application team | Private origin, certificate, application authentication and onboarding data |

Recommended initial boundary: one nonprod and one prod tunnel, each with two replicas. The map supports additional tunnels when credentials, ownership, capacity or risk justify separation. This is not hardcoded. Tier-specific tokens do not replace network isolation between tiers.

Existing zones may remain owned elsewhere: pass their `zone_id` to tunnel DNS records. Creating a record does not require taking ownership of its zone. Import existing resources into their exact intended Terraform addresses before adoption; review a no-replacement plan. Legacy Cloudflare directories are not automatically migrated.

## How the Terraform Works

1. The deployment root supplies `cloudflare_edge` and the separate sensitive `cloudflare_tunnel_secrets` map.
2. Global and per-tunnel enablement determine stable `for_each` keys. Removing a previously managed key plans deletion, not a pause.
3. `terraform_data.tunnel_secret_contract` requires a non-empty secret for each enabled tunnel. It does **not** validate secret entropy, VM credential handoff, installation or health. The old README incorrectly claimed cross-side verification.
4. The tunnel helper creates the tunnel, remote configuration and optional Access resources. `config_src` must be `cloudflare` because this module owns remote ingress.
5. Ordered ingress rules are followed by `http_status:404` by default. Do not add an earlier hostname-less catch-all or override the terminal rule to expose a service without review.
6. Tunnel DNS defaults to proxied CNAMEs targeting the created tunnel. Creation now depends on configuration and declared Access resources. This does not prove Access coverage or connector health. Top-level generic `records` do not have that tunnel-specific dependency.
7. The release script securely transfers runtime tokens to Key Vault; the Windows pattern retrieves them on-host and starts the service. Token outputs alone still do not start a connector.

The deployment root enables `enforce_enterprise_controls = true`. It requires exact approved hostnames, external-app classification, HTTPS with TLS verification, terminal 404 and narrow Access selectors or an explicit alternative-authentication justification. Tunnel CNAMEs must match ingress hostnames; generic top-level records are rejected in this profile. Legacy direct pattern consumers remain opt-in for compatibility. These checks do not replace identity-policy review or prove that a declared external origin is actually private.

Keep the Cloudflare **4.x** constraint and reviewed lock file. The [official Terraform guide](https://developers.cloudflare.com/tunnel/guides/terraform/) has different v4/v5 schemas. A v5 upgrade needs its own state/schema migration and nonprod review; do not mix snippets or simply change the constraint.

## Zero Trust Prerequisites and Inputs

Start with the requested [Cloudflare Tunnel get-started guide](https://developers.cloudflare.com/tunnel/get-started/). Its successful quickstart is not a production acceptance test.

Obtain actual Cloudflare account/zone IDs, approved external hostnames, existing DNS ownership, private origin URLs/certificates, Zero Trust IdP/group IDs and scoped API permissions. Check product entitlements with the account owner; this code does not purchase or enable every enterprise security feature.

| Input | Required when | Source / meaning |
|---|---|---|
| `cloudflare_edge.enabled` | Deploying the root | Explicit enablement; template is disabled |
| `tunnels.<key>.account_id`, `name` | Enabled tunnel | Actual account and approved name |
| `cloudflare_tunnel_secrets` | Enabled tunnel | Sensitive map keyed by tunnel key or `tunnel_secret_key`; approved cryptographically generated base64 secrets |
| `ingress_rules` | Publishing apps | Approved hostname, private service URL and optional path/origin settings |
| `dns_records` | This state owns publication | Existing `zone_id` or locally owned `zone_key`, and record name |
| `access_applications`, `access_policies` | Access protection required | Domain and explicit identity/service authorization |
| `zones` | This state owns the zone | Optional; not needed just to reference existing zone IDs |
| `records`, `rulesets` | Separately approved configuration | Optional, not an automatic security baseline |

For policies, choose an existing `application_id` or a declared `application_key`, unique precedence per app and meaningful include selectors. `group` selectors refer to Cloudflare Access groups, not arbitrary Entra group IDs; IAM owns that mapping. The enterprise profile rejects empty include objects, everyone/any-valid-token shortcuts and bypass policies.

For interactive apps, restrict approved IdPs/groups and enforce the agreed MFA/session controls. For machine clients, approve a scoped service-auth design. Do not use broad `everyone` Allow or Bypass as a shortcut. Some public customer apps legitimately use other authentication, but record that exception: absence of Access does not make a hostname private. See [Access policy semantics](https://developers.cloudflare.com/cloudflare-one/access-controls/policies/).

### Example: Access-Protected External Application

Access-protected tunnels must set `access_team_name` to their actual Zero Trust
team slug, not a URL. The helper configures connector-side JWT validation and
derives audiences from the declared Access application outputs, not copied IDs.
The enterprise profile requires canonical base64-encoded 32-byte tunnel secrets;
format validation cannot prove entropy, so generate these securely.

Merge this shape into the edge root, replacing every placeholder. Keep DNS empty during initial rollout; add publication only after acceptance. No credentials belong in this example.

```hcl
cloudflare_edge = {
  enabled  = true
  zones    = {} # Existing zone stays with its current owner.
  records  = {}
  rulesets = {} # Security baseline retains its existing owner.
  approved_public_applications = {
    "pilot.example.com" = { classification = "external-apps", approval_reference = "REPLACE_WITH_APPROVED_CHANGE" }
  }
  tunnels = {
    external_nonprod = {
      account_id = "REPLACE_WITH_CLOUDFLARE_ACCOUNT_ID"
      name       = "compeer-external-nonprod"
      config_src = "cloudflare"
      access_team_name = "REPLACE_WITH_ZERO_TRUST_TEAM_SLUG"
      ingress_rules = [{
        hostname = "pilot.example.com"
        service  = "https://REPLACE_WITH_PRIVATE_ORIGIN_FQDN:443"
        origin_request = {
          no_tls_verify      = false
          origin_server_name = "REPLACE_WITH_CERTIFICATE_DNS_NAME"
          http_host_header   = "REPLACE_WITH_APPLICATION_HOST_HEADER"
        }
      }]
      catch_all_service = "http_status:404"
      dns_records = {
        pilot = { zone_id = "REPLACE_WITH_EXISTING_ZONE_ID", name = "pilot.example.com" }
      }
      access_applications = {
        pilot = {
          name             = "Pilot external nonprod"
          domain           = "pilot.example.com"
          allowed_idps     = ["REPLACE_WITH_CLOUDFLARE_IDP_ID"]
          session_duration = "8h"
        }
      }
      access_policies = {
        pilot_users = {
          application_key = "pilot"
          name            = "Approved pilot users"
          decision        = "allow"
          precedence      = 1
          include         = [{ group = ["REPLACE_WITH_CLOUDFLARE_ACCESS_GROUP_ID"] }]
        }
      }
    }
  }
}
```

Use HTTPS to origins with certificate validation enabled. `origin_server_name` must match the certificate; the application Host header can differ. Install private CA trust, including any `ca_pool` file, on every replica. The enterprise profile rejects HTTP origins and `no_tls_verify = true`. See [origin parameters](https://developers.cloudflare.com/tunnel/reference/origin-parameters/).

## Credentials and Secure Handoff

| Credential | Consumer | Recommended boundary |
|---|---|---|
| Cloudflare API token | Edge Terraform provider | Sensitive `CLOUDFLARE_API_TOKEN`, scoped to necessary account/zone resources and actions |
| Base64 tunnel secret | v4 tunnel creation | Sensitive Terraform input, never committed |
| Tunnel runtime token | Replicas of that tunnel | Approved secret-store delivery; different from API token and raw tunnel secret |
| Azure deployer | Connector workspace | Azure OIDC identity limited to owned resources |
| Connector managed identity | Runtime secret retrieval | Key Vault RBAC for required secrets only |

Do not give hosts or the Azure connector workspace the Cloudflare API token. Do not use a Global API key. Have the account administrator approve current Tunnel, DNS, Access and ruleset API token permissions, including reads required for refresh.

`sensitive` redacts normal output; it does not remove values from state. This v4 implementation persists credentials in state. Restrict state/output/plan downloads, encrypt the backend, audit access, limit agents and output sharing, and prevent debug-log exposure.

Implemented handoff: `scripts/tunnel_release.py sync-token INVENTORY.json` retrieves each current tunnel token directly from Cloudflare and writes it to its approved Key Vault secret using the release job's Azure CLI OIDC session. It does not print tokens or put them in command arguments. Unchanged tokens do not create another secret version. The job needs scoped Cloudflare token-read permission and Key Vault secret read/write; it does not rotate tokens implicitly. The VM uses secret-scoped Key Vault Secrets User RBAC and its system identity. Test vault networking, RBAC propagation and secret existence before bootstrap. Initial synchronization must precede secret-scoped role assignment.

Prefer an ACL-restricted token file rather than a literal token in process arguments, custom data or image build logs. `--token-file` needs cloudflared 2025.4.0 or newer; validate service-account access on the chosen OS. See [runtime parameters](https://developers.cloudflare.com/tunnel/reference/run-parameters/).

## Connector Rollout

The root now contains the document's four-VM inventory, explicitly selecting Windows 2022:

| Tier | VM name | Zone | Private IP |
|---|---|---|---|
| Nonprod | `cus-np-cft-01` | 1 | `10.102.3.4` |
| Nonprod | `cus-np-cft-02` | 2 | `10.102.3.5` |
| Prod | `cus-prod-cft-01` | 1 | `10.102.3.6` |
| Prod | `cus-prod-cft-02` | 2 | `10.102.3.7` |

Specified subnet: `prod-cftagent-subnet`, `10.102.3.0/26`, Central US. The root selects D4s_v5, StandardSSD_LRS and Network Watcher Windows. Set `windows_image_version` to an approved `MicrosoftWindowsServer:WindowsServer:2022-datacenter-g2` version; production rejects `latest`. Domain join uses JsonADDomainExtension and separate sensitive credentials. Set `license_type = "Windows_Server"` only with confirmed Azure Hybrid Benefit entitlement. MDE onboarding remains with the existing Defender for Servers/policy owner; verify the subscription plan, policy scope and host onboarding, rather than adding a competing extension.

Each connector selects `hub_key` and `subnet_key`. `hub_workspaces` names the approved producer states. Their public `hub_virtual_network_id` and `subnet_ids` outputs are read and checked together; no VNet ID is hardcoded or managed by this state. Add another producer for a second hub and select it per VM. NIC/subnet subscriptions must match: if hubs are in different subscriptions, use one deployment of this root per subscription and include only that subscription's connectors. Every replica must reach every origin assigned to its tunnel; two different hubs are not automatic cross-region disaster recovery.

The document also has an NSG source entry for `10.102.3.64/26`, inconsistent with the VM inventory's `10.102.3.0/26`. Network engineering must confirm the intended permit range; do not guess.

`windows_bootstrap` is keyed by VM key. Supply `cloudflared_version`, verified `binary_sha256`, `key_vault_id`, `key_vault_uri`, `token_secret_name` and a per-replica `rollout_revision`. The managed Run Command uses the VM agent without SSH/WinRM, downloads the exact release, verifies SHA256 before replacing the binary, retrieves the token through IMDS/Key Vault, protects files to SYSTEM/Administrators, configures Windows service recovery and loopback-only readiness/metrics, rotates local logs, and registers startup token refresh. It checks execution success and local `/ready`; this does not validate origins or external authentication. Domain join runs before other declared extensions/bootstrap. Runtime scripts and references are in Terraform state, but the runtime token is fetched only inside the VM.

Production requires bootstrap for every VM, a pinned image and at least two distinct zones per token/secret group. The root also requires AMA/DCR ownership for every connector. Use the existing `phase2_agents` path with `os_type = "Windows"`; add its UAMI to each VM. If policy owns AMA, set `install_agent = false` and confirm the existing agent while preserving a single DCR-association owner. No log workspace, private endpoint, DCR or MDE onboarding value is invented.

For an upgrade/rotation, change one replica's version/hash/revision at a time, apply and verify both replicas before changing its peer. Changing the entire fleet's configuration in one apply can restart all hosts; Terraform does not itself implement rolling scheduling. Use reviewed per-replica commits/stages and inspect the plan. Startup refresh is not a fleet-wide rotation timer. Administrator passwords and optional domain-join passwords still appear in protected Terraform state and require restricted access.

Run two replicas per tier on separate VMs/zones using that tier's tunnel credentials. Four tunnel connections from one process are not two-host redundancy. Approve outbound TCP/UDP 7844 to Cloudflare's published endpoints as appropriate for HTTP/2/QUIC. Separately allow required DNS, secret retrieval, updates and private origin ports. Keep a named owner for endpoint-list updates; see [replica and firewall guidance](https://developers.cloudflare.com/tunnel/configuration/).

Validate the actual Palo Alto path and return routes, peering, NSGs and private origin DNS. Tunnel authentication does not prove those paths. No public inbound connector port or public connector IP is necessary.

## Release Tooling and Acceptance Gates

The helper accepts a reviewed JSON array containing only references:

```json
[
  {
    "account_id": "REPLACE_WITH_ACCOUNT_ID",
    "tunnel_id": "REPLACE_FROM_EDGE_TUNNEL_IDS_OUTPUT",
    "vault_uri": "https://REPLACE_WITH_VAULT.vault.azure.net",
    "secret_name": "cloudflare-nonprod-token",
    "minimum_replicas": 2
  }
]
```

Add a separate prod entry/secret. Obtain IDs from the edge root's non-secret `tunnel_ids` output; never copy runtime token outputs into this inventory. Run from a private release agent that can reach Key Vault:

```sh
python3 scripts/tunnel_release.py sync-token INVENTORY.json
# Review a saved Azure connector plan before apply (JSON contains secrets):
python3 scripts/tunnel_release.py check-rollout PLAN.json
# Apply the configured Azure connector root, then verify:
python3 scripts/tunnel_release.py verify-replicas INVENTORY.json --timeout 300
```

The helper requires Python 3, `CLOUDFLARE_API_TOKEN`, and an existing OIDC Azure CLI login for synchronization. Verification counts distinct active connector IDs, not four transport connections as four replicas. It does not rotate credentials or prove application access. Keep authenticated synthetic tests and unauthorized rejection tests in the application release pipeline; do not place service-auth tokens in inventory or Git.

`check-rollout` requires no credentials. It rejects Windows VM replacement and changes to more than one existing runtime command in the same tunnel group. Initial creation is allowed. Protect the plan JSON as secret-bearing data and delete it under the release agent's cleanup policy. Intentional scope changes/replacements require a separate reviewed cutover, not bypassing the gate for normal upgrades. Wire these steps into the organization's actual CI/HCP approvals; adding a helper alone does not install a pipeline gate.

1. Approve classification, ownership, OS, prod/nonprod isolation, origins, certificates, identity and change record. Import existing resources before adoption.
2. Confirm network and Key Vault access. Keep routing changes with their existing owners.
3. Apply tunnel, ingress and security configuration with publication DNS maps empty. Generic records must not publish prematurely either.
4. Provision approved VM infrastructure and run runtime automation. Wait for both replicas in each tier.
5. Test private HTTPS, certificate validation, unauthorized rejection and approved user/service access. Validate edge protections and restrict alternate paths to origins.
6. Add DNS publication, apply and run external synthetic tests. Promote through separate prod approval.
7. Stop one replica, test continuity, restore it and repeat. Check origin and firewall logs.
8. Verify reboot recovery, alert delivery, patch/rotation runbooks and a clean follow-up plan.

These are explicit pipeline stages, not routine `-target` instructions. The module's dependency graph does not coordinate runtime health across workspaces. Acceptance flags require evidence, not merely setting booleans.

Monitor service logs, replica count, tunnel degradation, certificate expiry and external transactions. A Healthy tunnel can still have an unreachable origin. Keep metrics private and deliver actionable alerts to platform/SOC. AMA or VM diagnostics alone do not configure all cloudflared log collection or Cloudflare Access/WAF audit export; supply DCR/export/retention explicitly. See [observability guidance](https://developers.cloudflare.com/tunnel/observability/).

## Automation Challenges and Mitigations

These are expected integration risks, not claims that every organization operates identically.

| Challenge | Recommended Terraform/release control |
|---|---|
| DNS, IAM, network and compute have different owners | Separate state ownership, explicit contracts, PR owners and readiness gates |
| Hostname accidentally lacks authentication | Per-host security inventory, approved exception process and negative access tests |
| Secrets in state/scripts/support logs | Restricted backend/agent access, runtime Key Vault retrieval, redaction and audited handoff |
| Successful apply but no working connector | Runtime stage and health/application tests, not resource-existence checks |
| RBAC/API/DNS eventual consistency | Bounded retries with redacted errors and timeouts in integration jobs; fail safely |
| Breaking v4/v5 provider changes | Lock versions and review schema/import migration in nonprod |
| Console edits and overlapping state ownership | Scheduled plans, audit logs, break-glass reconciliation; no blanket ignore_changes |
| Updating both replicas interrupts service | One-at-a-time upgrade gates and retained last-known-good artifacts |
| Shared fleet has excessive reach | Tier-specific tokens, explicit origin permits, capacity monitoring and justified fleet splits |
| Ingress ordering changes routing | Specific rules before broad rules, terminal 404, hostname/path tests |
| Removal destroys live publication | Protected production permissions, reviewed destroys and deliberate drain/unpublish |

### Rotation and Recovery

Choose one rotation authority and reconcile it with Terraform's v4 secret/state ownership. Do not assume an out-of-band rotation updates hosts. Cloudflare's [token lifecycle guidance](https://developers.cloudflare.com/tunnel/reference/tunnel-tokens/) notes that rotation prevents new connections with old tokens while existing connections can remain. For routine rotation, distribute the new token and restart in controlled batches. For compromise, rotate and force-disconnect sessions as required, accepting interruption if necessary. Rehearse in nonprod.

Restore the last approved ingress/security configuration and runtime artifact for rollback; never remove Access to restore availability. DNS withdrawal is not instant revocation for cached clients. Retain blocking controls and revoke compromised credentials.

## Verification and Open Work

Run `terraform init -backend=false`, `terraform validate` and `terraform test` in this pattern and the tunnel helper module. Mocks test Terraform behavior, not live API permissions, licensing, service installation, routing or failover.

Implemented code covers Windows provisioning, bootstrap, token handoff, multi-hub references, Windows monitoring composition, managed-WAF execute configuration and fail-closed publication controls. Before production, populate real approved inputs, confirm Defender/security/logging ownership, and record nonprod Windows reboot/upgrade/rotation/failover plus application acceptance results. No live credentials were provided for this development verification; this is not a live production certification or an automatic migration of deployed resources.
