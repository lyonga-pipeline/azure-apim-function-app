# Handling public-endpoint exceptions in the private-only landing zone

Compeer forces private connectivity everywhere. Some resources genuinely need
to be reachable from outside their private endpoint &mdash; the Palo Alto
firewalls pulling bootstrap files from a storage account, or authenticating to
Key Vault for certificates. This is how those exceptions are handled **in the
Terraform code**, in order of preference.

---

## Step 0 &mdash; you probably don't need a *public* endpoint

Two options keep the resource private and still let the firewalls reach it:

| Need | Private option | Notes |
|---|---|---|
| **Palo bootstrap &larr; storage** | **Service endpoint** (`Microsoft.Storage`) from the `palo_alto_management` subnet + `network_rules { default_action = "Deny", virtual_network_subnet_ids = [<mgmt subnet>] }` | Traffic stays on the Azure backbone. `publicNetworkAccess` stays `Enabled` (service endpoints require it) but the account is firewalled to one subnet. `shared_access_key_enabled = true` (bootstrap needs the key). **The subnet must have `service_endpoints = ["Microsoft.Storage"]` in the connectivity `hub_vnet.subnets` config** &mdash; Azure rejects a `virtual_network_subnet_ids` rule otherwise. |
| | **Private endpoint** for the `file` subresource on the mgmt subnet + `privatelink.file.core.windows.net` linked to the hub | Fully private (`public_network_access_enabled = false`). DNS must resolve at first boot &mdash; works because Azure-provided DNS auto-resolves a linked privatelink zone. |
| **Palo &rarr; Key Vault (certs)** | **Private endpoint** on the mgmt/trust subnet + `network_acls { default_action = "Deny", bypass = "AzureServices" }` + the firewall's **system-assigned identity** granted `Key Vault Certificates User` / `Secrets User` | The recommended PANW pattern. The MI auth works over the private endpoint. |

The `palo-alto-hub` pattern implements both:

```hcl
palo_alto = {
  bootstrap_storage_account = {
    name                          = "stpanbootstrapprod01"
    shared_access_key_enabled     = true
    public_network_access_enabled = true          # service-endpoint requirement, NOT open
    network_rules = {
      default_action      = "Deny"
      allowed_subnet_keys = ["palo_alto_management"]
    }
  }
  bootstrap_key_vault = {
    name      = "kv-pan-bootstrap-prod"
    tenant_id = "<tenant>"
    network   = { mode = "private" }
    private_endpoint = { name = "pep-kv-pan-bootstrap", subnet_key = "private_endpoints" }
  }
}
```

The firewall VM managed identities are granted vault access automatically
(`bootstrap_key_vault_rbac`).

---

## When public exposure is genuinely unavoidable

E.g. an external CRL/OCSP responder, a cross-cloud Panorama, or first-boot DNS
deemed too risky. Apply **all three** layers &mdash; each is a line of code.

### 1. Compensating control is mandatory in the module

The `storage-account` and `keyvault` modules now enforce a precondition:
`public_network_access_enabled = true` **requires** `network_rules` /
`network_acls` with `default_action = "Deny"` and at least one `ip_rules` /
`virtual_network_subnet_ids` entry. **"Public" can never mean "0.0.0.0/0"** &mdash;
it always means "reachable from an explicit allow-list".

### 2. Design-time carve-out on the policy (preferred)

Put the exception in a **dedicated resource group** (e.g. `rg-conn-palo-bootstrap`)
and add it to the guardrail's exempt list &mdash; visible in the policy
assignment, greppable, one RG of blast radius:

```hcl
# platform-governance workspace
governance.policy_baseline.exempt_resource_group_names = ["rg-conn-palo-bootstrap"]
```

This carves the RG out of `cmp-deny-public-paas` and `cmp-secure-storage` only.
Resources in it **still** get diagnostic settings, Defender, and Sentinel
coverage.

### 3. Audit-time exemption (for anything not RG-scopable)

`platform-policy` workspace, `policy.policy_exemptions`:

```hcl
palo-crl-egress = {
  scope_type           = "resource_group"
  resource_group_id    = "/subscriptions/<sub>/resourceGroups/rg-conn-palo-bootstrap"
  policy_assignment_key = "cmp-deny-pub-paas"   # or a full policy_assignment_id
  exemption_category   = "Mitigated"
  expires_on           = "2026-12-31T00:00:00Z"
  description          = "Palo bootstrap CRL check needs public egress; mitigated by Deny + on-prem CIDR allow-list. RISK-1234."
}
```

`Mitigated` + `expires_on` + a risk-record reference makes it an explicit,
expiring waiver on the compliance dashboard &mdash; not a silent hole.

---

## Keep it contained & observed

- Dedicated RG per exception; `data_classification` tag + `bt_owner` + an
  `exception` tag.
- `azurerm_management_lock` `CanNotDelete` on the storage account / vault.
- The `platform-policy` DINE remediation still deploys diagnostic settings on
  them &rarr; Sentinel sees every access.
- Consider a metric alert on the storage account for failed / anonymous auth.

## Decision tree

```
Does the firewall need <resource>?
 ├─ Reachable via service endpoint from the Palo mgmt subnet?  ── YES ─► network_rules Deny + allowed_subnet_keys. Done.
 ├─ Reachable via private endpoint + private DNS at first boot? ─ YES ─► private_endpoint block. Done.
 └─ Genuinely needs a public path?
      ├─ Put it in a dedicated RG
      ├─ Module precondition forces Deny + IP/subnet allow-list        (layer 1)
      ├─ policy_baseline.exempt_resource_group_names += that RG         (layer 2)
      └─ policy_exemptions entry (Mitigated, expires_on, RISK-ref)      (layer 3, if needed)
```
