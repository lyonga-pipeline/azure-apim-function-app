# Compeer Platform Policy Pattern

## Overview

**What this deploys:** the narrower, more frequently-changed half of Azure
Policy governance — everything that needs to promote from Audit→Deny, carry
a remediation identity, or grant a scoped exemption, separate from the
one-time management-group scaffold in `global-governance`.

| Area | Resource | Purpose |
|---|---|---|
| Policy definitions | `azurerm_policy_definition.definition` | Custom rules (e.g. `cmp-allowed-res-types`, `cmp-disk-encrypt-win`) |
| Policy initiatives | `azurerm_policy_set_definition.initiative` | e.g. `compeer-private-only-connectivity` (see below) |
| Assignments | `azurerm_management_group_policy_assignment.mg_assignment`, `.subscription_assignment` (subscription-scope), `.rg_assignment` (resource-group-scope, `policy_extensions.tf`) | Applies a definition/initiative at the named scope; only `mg_assignment` carries a remediation `identity` block |
| Exemptions | `azurerm_management_group_policy_exemption.mg_exemption`, `.rg_exemption`, `.subscription_exemption` (all `policy_extensions.tf`) | Time-boxed or permanent carve-outs for a specific scope |

**Why 3 assignment types and 3 exemption types instead of one generic
"assignment" resource:** Azure Policy assignments and exemptions are scoped
resources — an assignment at a resource group is a *different Terraform
resource type* (`azurerm_resource_group_policy_assignment`) than one at a
management group (`azurerm_management_group_policy_assignment`), even though
they take nearly identical arguments. This pattern mirrors that split 1:1
rather than hiding it behind one abstraction, so `terraform plan` always
shows exactly which scope a change lands at. `main.tf` holds the two most
commonly used (`mg_assignment`, `subscription_assignment`);
`policy_extensions.tf` holds the narrower/rarer ones (`rg_assignment`, and
all 3 exemption types) so the common path stays short.

**`var.remediation.dine_assignments` — a real, documented limitation:** this
mechanism only accepts a single `policy_definition_id` (no
`policy_set_definition_id`), so a DeployIfNotExists **initiative** (like
"Configure Microsoft Defender for Cloud plans") cannot be remediated through
it — it needs a plain `management_group_policy_assignment` with its own
`identity` block instead. See `implementations/platform-lz/PATTERN-REFERENCE.md`
§6 for the specific policies this affects.

**`moved.tf`:** resource labels here were renamed from the generic
Terraform default `"this"` to purpose-specific names (`.definition`,
`.initiative`, `.mg_assignment`, etc.) for readability. `moved.tf` records
the old→new address for every renamed resource so an already-applied
workspace's next `terraform apply` is a plain state move, not a
destroy/recreate. Safe to ignore when reading the pattern's logic.

---

This pattern owns Azure Policy definitions, initiatives, and assignments after the management-group hierarchy exists. It is intentionally separate from the governance root so policy promotion, remediation, managed-identity assignment, and deny-mode changes can run through a narrower HCP Terraform workspace.

Use `management_group_ids` from the governance workspace output. Do not configure the same policy definition or assignment in both governance and policy workspaces unless the resource has been deliberately imported and ownership transferred.

---

## Guardrail: private-only connectivity

Compeer forces **all inbound traffic through Cloudflare Tunnels** and requires
**private connectivity to every Azure resource**. There is no single Azure
setting for this — it is a policy initiative. Set `var.private_only_connectivity`
(exposed on the `platform-policy` workspace as
`policy.private_only_connectivity`):

```hcl
policy = {
  enabled = true
  private_only_connectivity = {
    enabled              = true
    management_group_key = "compeer"          # or the top LZ MG
    effect               = "Audit"            # start here, then "Deny"
    enforce              = true
    allowed_public_ip_resource_group_names = [
      "rg-conn-palo-alto",     # firewall untrust NICs + LB frontend
      "rg-conn-bastion",       # Azure Bastion (Bastion cannot be private)
      "rg-conn-route-server",  # Route Server (requires a public IP)
      "rg-hybrid-gateway",     # VPN / ExpressRoute gateway
      # add an AppGW RG here ONLY if a gateway must stay internet-facing
    ]
    not_scopes = [
      # optionally exclude a whole subscription/MG subtree during migration
    ]
  }
}
```

### What it deploys

| Object | Purpose |
|---|---|
| `deny-public-ip-address` (custom policy) | Deny `Microsoft.Network/publicIPAddresses` outside `allowed_public_ip_resource_group_names`. |
| `deny-nic-public-ip` (custom policy) | Deny NICs that attach a Public IP. |
| `compeer-private-only-connectivity` (initiative) | Bundles the two, plus any opted-in built-ins. |
| MG assignment | Applies the initiative at `management_group_key`, `enforce = true`. |

### Rollout

1. Deploy with `effect = "Audit"`. Review **Policy → Compliance** for a week.
2. Work the non-compliant list — the offenders are what the app-migration
   conversation is really about (see call-out below).
3. Flip `effect = "Deny"`. New public exposure is now blocked; existing
   resources are reported until remediated.

### Built-in companion policies (opt-in)

The custom policies stop *new* Public IPs. To also force **public network access
off on PaaS** (Storage, Key Vault, App Service, SQL, APIM, Cosmos, ACR, Event
Grid, AI Search, …), add the built-in "should disable public network access"
policies. Their definition GUIDs are **not shipped** here because they must be
verified against the tenant:

```bash
az policy definition list --query "[?contains(displayName,'disable public network access')].{name:displayName,id:id}" -o table
```

then:

```hcl
private_only_connectivity = {
  # ...
  include_builtin_baseline = true
  builtin_policy_definition_ids = {
    storage_pna   = "/providers/Microsoft.Authorization/policyDefinitions/b2982f36-99f2-4db5-8eff-283140c09693"
    keyvault_pna  = "/providers/Microsoft.Authorization/policyDefinitions/405c5871-3e91-4644-8a63-58e19d68ff5b"
    appservice_pna = "/providers/Microsoft.Authorization/policyDefinitions/1b5ef780-c53c-4a64-87f3-bb9c8c8094ba"
    sql_pna       = "/providers/Microsoft.Authorization/policyDefinitions/1b8ca024-1d5c-4dec-8995-b1a932b41780"
    # ... verify each GUID first
  }
}
```

Alternatively assign Microsoft's built-in initiatives directly through
`management_group_policy_assignments` (e.g. *"Configure Azure PaaS services to
use private DNS zones"*, *"Azure Security Benchmark"*).

---

## ⚠️ Call-out — this guardrail is a program, not a switch

Enabling `effect = "Deny"` **will break deployments** for anything that expects a
public endpoint. Before flipping to Deny, the following must be true:

| Resource type | Required change | Impact |
|---|---|---|
| **Application Gateway** | Internal-only frontend (`Private` frontend IP, no public frontend). WAF v2 still supports private-only. If a gateway must serve the internet, it goes in an allow-listed RG **and** sits behind Cloudflare. | Redeploy; DNS cutover. |
| **API Management** | `virtual_network_type = "Internal"` + private DNS for the gateway/portal/management endpoints. Developer/portal access moves to private network + Cloudflare/Bastion. | **Replace** (VNet mode change is ForceNew). Plan a migration window. |
| **App Service / Function App** (many) | `public_network_access_enabled = false` + Private Endpoint + VNet integration for outbound. Deployment via private runners or SCM Private Endpoint. | In-place for `public_network_access_enabled`; CI/CD runners must reach the private endpoint. |
| **Storage / Key Vault / SQL / Cosmos / ACR / Event Grid** | `public_network_access_enabled = false` + Private Endpoint + private DNS zone. | In-place toggle; every consumer needs the private endpoint + DNS. |
| **VM public IPs** | Remove. Access via Bastion or Cloudflare Tunnel + private connectivity. | Detach PIP; update runbooks. |
| **Bastion, Route Server, VPN/ExpressRoute GW, Palo untrust** | **Keep public** — Azure requires it. Pin them to allow-listed RGs. | None. |

Module defaults in this catalog were set **private-by-default** to match
(`public_network_access_enabled = false`), so a fresh deployment is compliant.
The work is the **existing estate** and the **app-migration playbook** (private
endpoints, private DNS, CI/CD reachability). Treat this guardrail as Audit-first
and drive the non-compliance list down before enforcing.

The Cloudflare side (what the tunnels expose, what is deployed, what must change)
is a separate review — owned outside this repo.

---

## Policy split: governance vs. platform-policy

| Concern | Workspace | Mechanism |
|---|---|---|
| MG hierarchy | `platform-governance` | `global-governance` pattern |
| Deny/audit **baseline** definitions + assignments | `platform-governance` | `global-governance` `policy_baseline` (Audit-first) |
| Microsoft Cloud Security Benchmark | `platform-governance` | `policy_baseline.assign_security_benchmark` |
| **Promote** a baseline policy to Deny | `platform-governance` | flip `policy_baseline.effect` (per policy once split out) |
| **Exemptions** (all 3 scopes) | **`platform-policy`** | `var.policy_exemptions` |
| RG-scoped assignments | **`platform-policy`** | `var.resource_group_policy_assignments` |
| **DeployIfNotExists remediation** | **`platform-policy`** | `var.remediation` (needs identity + Log Analytics) |
| Private-only connectivity guardrail | **`platform-policy`** | `var.private_only_connectivity` |

The old `policy-baseline` module is retired — this pattern is the single home for
exemptions and remediation.

## Exemptions

Every `policy_exemptions` entry sets `scope_type`
(`management_group` / `subscription` / `resource_group`), the matching scope id
(or `management_group_key`), and either a full `policy_assignment_id` or a
`policy_assignment_key` (a key into this pattern's own assignment maps).
`exemption_category` is `Waiver` or `Mitigated`; set `expires_on` for
time-boxed waivers. An exemption path must exist before any policy is promoted
to `Deny` (runbook §2.4).

## DeployIfNotExists remediation (`var.remediation`)

DINE / Modify assignments make the landing zone self-healing. They need a
`SystemAssigned` identity and a `location`, and run **after**
`platform-management` has created the Log Analytics workspace. Built-in policy /
initiative IDs are **caller-supplied and tenant-verifiable** — confirm each with:

```bash
az policy definition list \
  --query "[?policyRule.then.effect=='DeployIfNotExists'].{name:displayName,id:id}" -o table
```

Recommended starting set (verify IDs first):

| Purpose | Built-in policy (display name) |
|---|---|
| Activity logs → Log Analytics | *Configure Azure Activity logs to stream to specified Log Analytics workspace* — set `inject_law = true` |
| Resource diagnostics → Log Analytics | the per-resource-type *Deploy Diagnostic Settings for … to Log Analytics workspace* set, or the ALZ `Deploy-*-DiagnosticSettings` custom initiative |
| Defender for Cloud plans | *Configure Microsoft Defender for Cloud plans* (initiative) or the per-plan `Deploy-MDFC-*` policies |
| AMA + DCR on VMs | *Configure Windows/Linux machines to run Azure Monitor Agent* + *…association to Data Collection Rule* |
| Private DNS zone group on private endpoints | *Deploy - Configure private DNS zone group for …* (one per service, pass `privateDnsZoneId`) |
| VM backup | *Configure backup on virtual machines … to an existing recovery services vault* (pass `vaultLocation` + `backupPolicyId`) |

After apply, grant each assignment's `remediation_assignment_principal_ids` the
role its DINE policy requires (usually Contributor on the target scope, or
Log Analytics Contributor / Monitoring Contributor), then create a remediation
task.
