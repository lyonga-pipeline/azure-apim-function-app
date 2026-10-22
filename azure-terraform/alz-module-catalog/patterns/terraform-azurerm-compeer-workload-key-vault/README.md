# Workload Key Vault Pattern

Reusable WKL-07 foundation for one application, environment and region in an
existing workload subscription. It can be used directly by application teams or
embedded in the spoke blueprint. It creates the vault and only explicitly
requested endpoints, scoped access, keys, audit settings and metric alerts.

[Examples](examples/README.md) | [Inputs](#inputs) | [Outputs](#outputs) | [Upgrade](#existing-deployments) | [Security Guidance](#security-guidance)

## Security Contract

- **RBAC only**, as selected for Compeer. No legacy access-policy mode and no
  automatic deployment-principal data-plane grant.
- Private-only by default: public access disabled, firewall default Deny and
  trusted-service bypass off. Default endpoint and central DNS integration are
  retained for existing spoke consumers.
- Purge protection and 90-day soft-delete retention are mandatory in every
  environment. VM deployment, disk-encryption and ARM-secret bypass flags stay off.
- Required AuditEvent and AllMetrics export to an existing approved LAW.
  Externally owned diagnostics can be referenced, but not silently replaced,
  disabled or redirected to a different vault/workspace.
- Application identities/groups receive only explicitly selected vault-scoped
  data roles. Owner, Contributor, Key Vault Administrator, custom roles and
  individual-user assignments are not exposed by this pattern.
- Optional service-generated keys require initial expiration and automatic
  rotation. RSA defaults to 3072 bits; HSM-backed keys require Premium.
- No secret values, private keys, certificate imports, passwords or credentials
  are accepted in tfvars or published by outputs. Protect Terraform state and
  plan artifacts anyway: resource metadata and public key attributes are stored.

A simple vault is still private and audited. Turning off security controls is
not a simplification strategy. A documented restricted-public exception can use
narrow public egress CIDRs or existing service-endpoint subnets with default Deny;
it is **not** the Compeer spoke baseline and existing Azure Policy may prohibit it.
An exception reference is change metadata, not proof of authorization or a policy
exemption. Trusted-service bypass needs its own explicit choice/reference; it
also admits supported trusted services when public access is disabled.

## Usage

Use one separately managed application/environment root and backend/workspace.
For deployed consumers, replace the local development source below with the
actual published registry source and an **exact approved version**. This pattern
is not assumed to have a published registry release yet.

```hcl
module "workload_vault" {
  source = "../../patterns/terraform-azurerm-compeer-workload-key-vault"

  resource_group_name        = var.security_resource_group_name
  location                   = var.location
  tenant_id                  = var.tenant_id
  environment                = var.environment
  appcode                    = var.appcode
  private_endpoint_subnet_id = var.private_endpoint_subnet_id
  private_dns_zone_id        = var.central_key_vault_zone_id
  log_analytics_workspace_id = var.central_log_analytics_workspace_id
  tags                       = module.tags.tags

  secret_readers = {
    application = { principal_id = var.application_identity_object_id }
  }
}
```

The [runnable example root](examples) supplies typed variables, guarded provider
configuration and four actual tfvars variants. Its values are synthetic and
deployment is disabled. Advanced configuration includes keyed endpoints,
static private IPs/manual approval, existing audit sinks, rotating HSM-backed
keys and alerts using existing notification groups.

## Created And Reused

| Resource | Ownership |
| --- | --- |
| Key Vault | Always created here; an ID does not adopt an existing vault. |
| Private endpoints and DNS zone groups | One default endpoint via the original inputs, or an explicit map of endpoints; keys identify independent resources. |
| Resource groups, VNets/subnets and private DNS zones | Must already exist; never replaced or duplicated here. |
| DNS VNet links, forwarding and hub peering | Platform/network-owned; an endpoint does not establish these paths. |
| Entra identities/groups | Existing object IDs; this pattern creates only their selected vault-scoped assignments. |
| LAW, optional audit archive/Event Hub and action groups | Existing approved IDs; no shared platform resources or contacts are created/modified. |
| Diagnostic setting | Created by default; existing_setting references an exact externally owned compliant setting without import or modification. |
| Keys and metric alerts | None by default; created only when requested. |
| Defender, central SOC detections, policy/PIM, backups and incident response | Platform/security/operations-owned; not enabled at subscription scope by this pattern. |

Enabling or removing an optional entry affects its lifecycle: false/empty is
not a pause button and can plan deletion. Never manage the same resource from
two Terraform states. Existing grants/settings require import or an approved
ownership handoff before this state can manage them.

## Inputs

Terraform **>=1.11.4, <2** and AzureRM **>=4.42, <5**; use the tested 4.81 provider
selection in the examples. This pattern consumes the caller's azurerm provider.
It checks tenant identity and confines endpoint subnets to that provider's workload
subscription. No extra hub/DNS write provider or full-state access is required.

| Input | Type / Default | Purpose |
| --- | --- | --- |
| resource_group_name | string, required | Existing vault resource group. |
| location | string, required | Approved Azure region; also naming context. |
| tenant_id | UUID string, required | Must match the authenticated provider tenant. |
| environment, appcode | strings, required | Approved naming context, matching tags. |
| domain | string, internal-apps | Workload naming domain. |
| name | string, null | Approved globally unique name; null uses naming. A name change replaces the vault. |
| sku_name | standard / premium, standard | Premium supports HSM-backed keys; it is not dedicated Managed HSM. |
| private_endpoint_subnet_id, private_dns_zone_id | strings, null | Compatibility inputs for the default endpoint; both required unless private_endpoints is supplied. |
| private_endpoints | map(object), null | Explicit endpoint keys with subnet/zone IDs, optional name/RG/region/NIC/static IP/manual approval. Keep default when migrating the existing endpoint. |
| network_access | object, private mode | Optional restricted_public allowlists and separately explicit trusted-service exception. No Allow-all mode. |
| log_analytics_workspace_id | ARM ID, required | Approved central LAW, not its workspace GUID. |
| diagnostics | object, creation enabled | Name/table mode, optional additional archive/Event Hub, or existing_setting evidence with exact target/LAW and AuditEvent/AllMetrics. |
| secret_readers | map(object), {} | ServicePrincipal/Group object IDs granted Key Vault Secrets User. |
| secret_officer_group_ids | map(string), {} | Approved groups granted Secrets Officer. |
| data_access | map(object), {} | Additional allowed secret, crypto, certificate or reader roles; no broader management roles. |
| keys | map(object), {} | Generated RSA/EC keys, optional HSM, expiration and required rotation. ISO day durations only, e.g. P90D. |
| monitoring | object, disabled | Availability, latency and saturation alerts using existing action groups; thresholds/severity/frequency/window configurable. |
| timeouts | object, {} | Optional vault create/read/update/delete timeouts. |
| tags | map(string), required | Shared tag-module output/equivalent, including stable created_on and ownership/classification/cost tags. |

See [variables.tf](variables.tf) and the [advanced tfvars](examples/variants/advanced-private.tfvars)
for the complete nested schema. Firewall IP rules must be explicit IPv4 CIDRs,
/24 or narrower, and cannot use private/loopback/link-local/CGNAT/multicast ranges.
Service-endpoint subnets require Microsoft.KeyVault already enabled by their owner.
Private endpoint IPs must be free, in the selected subnet, and approved by IPAM;
syntax checking does not prove those live conditions.

Do not mix compatibility endpoint inputs with assumptions about an explicit
endpoint map: the explicit map is authoritative. Set private_endpoints={} only
for an approved restricted-public design. A private-mode vault cannot omit all
endpoints. Cross-subscription endpoints require a separate appropriately
authorized owner, not a silent provider-context switch here.

## Operational Prerequisites

The deployment identity needs scoped vault/endpoint writes, approved
role-assignment privileges, existing-zone read/join and audit-destination rights.
Pre-register the needed resource providers through the platform owner. Limit
control-plane writes and privileged data roles with PIM/change approval.

**Keys are data-plane operations.** The runner must already reach the vault and
have key management/rotation permissions, typically approved Crypto Officer.
New roles/private endpoints are not an immediate RBAC-propagation or DNS guarantee.
Use two reviewed stages when bootstrapping: create foundation, validate DNS/
connection approval and grant propagation, then enable keys. The pattern never
grants its runner access implicitly and never uses an arbitrary sleep to claim
readiness. Dedicated crypto pipelines can own keys separately by leaving keys={}.

Key rotation creates new versions; verify the consuming service supports the
versionless URI and actually refreshes it. Keep prior versions needed to decrypt
existing data. Initial expiration must be a future UTC date when deploying.
Near-expiry policy emits events; delivery/response still needs an approved
Event Grid consumer or SOC workflow, which this pattern does not create.

Diagnostics table mode defaults unchanged for existing consumers. Dedicated is
an explicit SOC query/schema decision. LAW retention, immutable archive controls,
Event Hub authorization/firewalls and alert action-group delivery are managed
by their existing owners. Reused diagnostics are validated declarations, not
independent proof of their live settings.

The additional recovery endpoint in the example is a second network access
path, **not another vault or cross-region replication**. Define application
RPO/RTO, use separate regional vaults when appropriate, and test encrypted object
backup/restore procedures with the security owner. Purge protection is not a
complete backup strategy. Certificate/secret issuance, expiration and rotation
belong to separately authorized lifecycle automation, not plaintext tfvars.

## Outputs

No secret material is returned:

| Output | Contract |
| --- | --- |
| id, name, uri | Vault identity and data-plane URI. |
| private_endpoints | Observed ID, subnet, target, zone IDs and NIC IDs per endpoint key. |
| private_endpoint_id, private_endpoint_configuration | Compatibility accessors for default; null when no default endpoint exists. |
| role_assignment_ids, role_assignments | Observed vault-scoped grants and IDs. |
| diagnostic_setting_id, diagnostic_ownership | Managed/referenced setting and policy-ownership metadata. |
| security_configuration | Observed helper attributes, not desired constants. |
| key_ids, key_versionless_ids | Versioned/versionless generated-key identifiers. |
| metric_alert_ids | Optional operational alert IDs. |

## Existing Deployments

Existing input defaults and security settings remain unchanged. The moved block
preserves module.private_endpoint as module.private_endpoint["default"]; keep the
default key when upgrading an existing deployment. Existing diagnostics retain
their indexed address. Review a plan in the **same state** and expect address
moves, not endpoint/vault replacements. Do not combine naming, subscription,
network exposure, diagnostic ownership or key-lifecycle changes into that move.
Existing custom names must remain explicit.

Purge protection cannot be disabled after enabling it. Configure the caller's
AzureRM features not to purge vaults/keys on destroy. Deleted names remain
reserved during retention; plan recovery rather than disabling production
controls for tests. No resource locks or budgets are added.

## Verification

Run init/test in this module, and see [examples/README.md](examples/README.md)
for each actual tfvars variant. The catalog regression includes positive/
negative pattern tests, real example configurations, helper tests and the spoke
composition. Mock tests are not evidence of Azure deployment or WAF certification.

Before go-live validate provider tenant/subscription, actual DNS/private IP and
approved connection status, effective RBAC from a real workload identity,
AuditEvent ingestion and alert delivery, Defender coverage, key version refresh/
rotation, recovery procedures and SOC ownership. Existing Azure integration
coverage is provided by the spoke's opt-in
[integration runbook](../terraform-azurerm-compeer-spoke-landing-zone/integration-tests/README.md);
it is not run or claimed complete by local tests.

## Security Guidance

This is WAF-aligned engineering guidance, not a certification or a universal
application-specific threat model:

- [Microsoft: secure Azure Key Vault](https://learn.microsoft.com/en-us/azure/key-vault/general/secure-your-key-vault).
- [Microsoft: RBAC versus legacy access policies](https://learn.microsoft.com/en-us/azure/key-vault/general/rbac-access-policy).
- [Microsoft: network restrictions and trusted services](https://learn.microsoft.com/en-us/azure/key-vault/general/network-security).
- [Microsoft: cryptographic key rotation and client version handling](https://learn.microsoft.com/en-us/azure/key-vault/keys/how-to-configure-key-rotation).
- [Microsoft: Key Vault reliability](https://learn.microsoft.com/en-us/azure/key-vault/general/disaster-recovery-guidance).
- [Microsoft: supported Key Vault metrics](https://learn.microsoft.com/en-us/azure/azure-monitor/reference/supported-metrics/microsoft-keyvault-vaults-metrics).
