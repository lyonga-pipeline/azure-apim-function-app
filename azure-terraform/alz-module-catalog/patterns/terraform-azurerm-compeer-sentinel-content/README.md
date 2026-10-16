# Sentinel Content Pattern

Microsoft Sentinel content as code: data connectors, analytics rules,
automation rules and watchlists on an existing, Sentinel-onboarded Log
Analytics workspace. Deployed by the `platform-sentinel` workspace after
`platform-management`.

The pattern exists so the SOC can change detections through a pull request
without touching the platform-management state, and so a rule can never be
deployed against a table nothing feeds.

## How Sentinel is normally set up in Terraform

Sentinel is not one resource. It is seven layers, owned by different states:

| Layer | What it is | Terraform mechanism | Owner here |
| --- | --- | --- | --- |
| 0. Workspace and onboarding | Log Analytics workspace, Sentinel enabled on it | `azurerm_log_analytics_workspace`, `azurerm_sentinel_log_analytics_workspace_onboarding` | `platform-management` (this pattern can onboard only with `manage_onboarding = true`) |
| 1. Telemetry plumbing | Getting data into the workspace | Diagnostic settings (Activity Log, Entra, resource logs), data collection rules + Azure Monitor Agent (CEF, Syslog, Windows events), Azure Policy `DeployIfNotExists` for scale | `platform-management` (Activity Log, Entra), `platform-policy` (resource-log DINE), forwarder owners (CEF) |
| 2. Data connectors | The connector objects Sentinel shows as "connected" | `azurerm_sentinel_data_connector_*` | **this pattern** |
| 3. Detections | Analytics rules | `azurerm_sentinel_alert_rule_*` | **this pattern** |
| 4. Response | Automation rules, playbooks | `azurerm_sentinel_automation_rule`; Logic Apps are separate | rules: **this pattern**; playbooks: SOC/automation owner |
| 5. Reference data | Watchlists | `azurerm_sentinel_watchlist`, `_item` | **this pattern** |
| 6. Governance | Who may change what, what must be enabled | Azure RBAC, Azure Policy, CI review of this repo | `platform-authorization`, `platform-policy` |

Three different mechanisms deliver data, and only one of them is an azurerm
connector resource. This is the usual source of confusion:

1. **API connectors** (Defender XDR, Entra ID Protection alerts, Defender for
   Cloud, Office 365, threat intelligence): one `azurerm_sentinel_data_connector_*`
   resource each. This pattern owns them.
2. **Diagnostic-setting feeds** (Azure Activity, Entra sign-in and audit logs,
   resource logs): there is no azurerm Sentinel connector resource. The data
   arrives because a diagnostic setting exports to the workspace. The Entra ID
   connector resource connects alerts only; sign-in and audit **logs** need the
   tenant diagnostic setting.
3. **Agent feeds** (Palo Alto CEF, Syslog, Windows Security Events): a data
   collection rule plus Azure Monitor Agent on the forwarder. No connector
   resource either.

"Policy" appears twice in a Sentinel design. **Azure Policy** forces telemetry to
exist (diagnostic settings, Defender plans) and lives in `platform-policy`; it
cannot enable a connector or create a rule. **Sentinel content** (rules,
automation) decides what to do with the data and lives here. This pattern
bridges the two with a dependency contract instead of duplicating policy.

## What it creates

- Optional workspace onboarding (`manage_onboarding`, default off).
- Data connectors, named like the legacy `terraform-azurerm-compeer-sentinel`
  module (`aad`, `mdatp`, `ti`, `mdc`) so an adopted connector can be imported:
  Entra ID, Defender XDR, Defender for Endpoint, Defender for Identity,
  Defender for Cloud Apps, Defender for Office 365, Office 365, Purview Insider
  Risk Management, Power BI, Defender for Cloud (one per subscription), threat
  intelligence, Microsoft threat intelligence feed, TAXII feeds.
- Data source integration (`ingestion`): data collection endpoints, custom
  tables with retention, data collection rules and their associations, for
  agent feeds (Windows Security Events, Windows event logs, Syslog, CEF) and for
  third-party pipelines that push through the Logs Ingestion API (Cribl
  delivering Cloudflare logs). Each pipeline rule can grant its Entra
  application Monitoring Metrics Publisher on that one rule.
- Analytics rules: scheduled and near-real-time (with entity mapping, alert
  detail overrides, suppression, incident grouping and MITRE tactics and
  techniques), Microsoft security incident creation rules, template rules
  (fusion, threat-intelligence mapping, ML behavior analytics) and built-in
  anomaly rules.
- Automation rules with typed conditions, scoped to rules created here by key,
  with incident-modify, incident-task and playbook actions.
- Watchlists with inline rows.
- An opt-in baseline library of five identity and governance detections.

## Connector catalog for an Azure and on-premises organization

Where each common source comes from and which state owns it. "Source key" is the
name a rule lists in `requires_sources`.

| Source | Mechanism | Terraform location | Source key |
| --- | --- | --- | --- |
| Entra sign-in and audit logs | Tenant diagnostic setting | `platform-management` (`entra_diagnostic_settings`) | `entra_signin_logs`, `entra_audit_logs` |
| Entra ID Protection alerts | Connector `entra_id` | this pattern | `security_alert` |
| Azure Activity | Subscription diagnostic setting | `platform-management` | `azure_activity` |
| Defender XDR, Endpoint, Identity, Cloud Apps, Office 365 | Connectors | this pattern | `security_alert` |
| Defender for Cloud | Connector, one per subscription | this pattern | `security_alert` |
| Office 365 (Exchange, SharePoint, Teams), Insider Risk, Power BI | Connectors | this pattern | `office_activity` |
| Threat intelligence (platform, Microsoft feed, TAXII) | Connectors | this pattern | `threat_intelligence_indicator` |
| Azure resource logs (Key Vault, firewall, NSG, Storage, SQL, App Gateway) | Diagnostic settings | owning patterns, `platform-policy` DINE as backstop | `azure_diagnostics` |
| VNet flow logs and Traffic Analytics | Flow-log policy | `platform-policy` | Traffic Analytics tables |
| Windows Security Events (domain controllers, servers, Arc machines) | AMA + data collection rule | `ingestion` preset `windows_security_events` | `windows_security_events` |
| Windows DNS, AD and other event logs | AMA + data collection rule | `ingestion` preset `windows_events` | `Event` table (no source key) |
| Linux Syslog | AMA + data collection rule | `ingestion` preset `syslog` | `syslog` |
| Palo Alto and other CEF firewalls | AMA on a forwarder + data collection rule | `ingestion` preset `cef` | `common_security_log` |
| Third-party SaaS through a pipeline (Cloudflare through Cribl) | Logs Ingestion API into a custom table | `ingestion` preset `custom_ingestion` | the table name, for example `Cloudflare_CL` |

Not covered here: AWS and GCP connectors, ServiceNow and other ticketing
integrations (Security Operations), and any source whose owner has not decided
how it will deliver.

## Third-party feeds through Cribl (Cloudflare example)

Cribl does not use a Sentinel connector. It posts to the Logs Ingestion API,
which needs a data collection endpoint, a data collection rule, a custom table,
and an Entra application allowed to publish to that rule. The pattern builds the
first three and the permission; the application and its secret are created
outside it:

```hcl
ingestion = {
  resource_group_name = "<management resource group>"
  location            = "centralus"
  endpoints = {
    logs = { public_network_access_enabled = true } # decide: reachable from Cribl, or private link
  }
  custom_tables = {
    Cloudflare_CL = {
      retention_in_days       = 90
      total_retention_in_days = 548
      columns = [
        { name = "TimeGenerated", type = "dateTime" },
        { name = "ClientIP", type = "string" },
        { name = "EdgeResponseStatus", type = "int" },
        { name = "Raw", type = "dynamic" },
      ]
    }
  }
  rules = {
    cloudflare = {
      preset                  = "custom_ingestion"
      endpoint_key            = "logs"
      table_key               = "Cloudflare_CL"
      publisher_principal_ids = ["<object ID of Cribl's Entra application>"]
    }
  }
}
```

The `ingestion_targets` output returns what to enter in Cribl's destination: the
endpoint URL, the rule's immutable ID and the stream name. Use the table's real
schema from your Cloudflare log fields; `TimeGenerated` is required. If Cribl
sends a different shape than the table, set `input_stream_name`,
`stream_columns` and `transform_kql` on the rule and the pattern routes it into
the table. Re-creating this later is a code change, not a manual rebuild: the
table, endpoint and rule are all in the repository.

## Terraform and manual configuration drift

Terraform only manages what is in its tfvars. Connectors a person enables in the
portal, content hub solutions and rules created by hand are left alone. Drift
appears in two places:

- **Objects Terraform owns that someone edits in the portal.** The next apply
  reverts the edit. This matters most for analytics rules the SOC tunes. Keep
  tuned rules out of the tfvars (the SOC owns them in the portal), or keep them
  in Terraform and tune through a pull request. Decide per rule; do not split one
  rule between both.
- **Connectors and data collection plumbing.** These are set once and rarely
  edited, so they drift least and benefit most from being in code (an
  accidental delete is a plan diff, not an outage).

`plan` shows exactly which objects differ, so a scheduled plan against this
workspace is a drift report. If the SOC prefers to create rules in the portal
and have Terraform stop reverting them after creation, that needs a separate
ownership mode that this pattern does not provide yet.

## Dependency contract

Each rule declares `requires_sources`, the feeds its query reads:
`azure_activity`, `entra_audit_logs`, `entra_signin_logs`,
`common_security_log`, `security_alert`, `threat_intelligence_indicator`,
`office_activity`, `syslog`, `windows_security_events`, `azure_diagnostics`.

A source is available when an enabled connector in this state delivers it
(for example any alert connector provides `security_alert`) or when you list it
in `externally_provided_sources` because another state owns the feed. Enabling a
rule whose source is not available **fails the plan** and names the rule and the
missing source. Disabled rules are not checked. `enforce_source_dependencies =
false` keeps the gap visible in the `source_coverage` output without blocking,
for a staged rollout.

Declare an external feed only after its owner has data arriving, not when the
export is merely configured.

## Usage

```hcl
module "sentinel_content" {
  source = "../../patterns/terraform-azurerm-compeer-sentinel-content"

  log_analytics_workspace_id = var.log_analytics_workspace_id
  tenant_id                  = var.tenant_id

  data_connectors = {
    defender_for_cloud = { default = {} }
    entra_id           = true
  }
  externally_provided_sources = ["azure_activity", "entra_audit_logs", "entra_signin_logs"]

  baseline_content = { enabled = true }

  microsoft_incident_rules = {
    defender-for-cloud-high-medium = {
      display_name    = "Defender for Cloud - High and Medium"
      product_filter  = "Azure Security Center"
      severity_filter = ["High", "Medium"]
    }
  }

  scheduled_rules = {
    breakglass-signin = {
      display_name     = "Break-glass account sign-in"
      severity         = "High"
      query_frequency  = "PT5M"
      query_period     = "PT5M"
      tactics          = ["InitialAccess"]
      techniques       = ["T1078"]
      requires_sources = ["entra_signin_logs"]
      query            = <<-KQL
        let breakglass = _GetWatchlist('breakglass-accounts') | project UserPrincipalName;
        SigninLogs | where UserPrincipalName in (breakglass)
      KQL
      entity_mappings = [
        { entity_type = "Account", field_mappings = [{ identifier = "FullName", column_name = "UserPrincipalName" }] },
      ]
    }
  }

  watchlists = {
    breakglass-accounts = {
      display_name    = "Break-glass accounts"
      item_search_key = "UserPrincipalName"
      items = {
        bg1 = { UserPrincipalName = "bg1@example.com" }
      }
    }
  }

  automation_rules = {
    triage-breakglass = {
      display_name       = "Triage: break-glass sign-in"
      order              = 10
      analytic_rule_keys = ["breakglass-signin"]
      modify_incident    = [{ order = 1, status = "Active", severity = "High", labels = ["breakglass"] }]
      incident_tasks     = [{ order = 2, title = "Confirm with the break-glass custodian" }]
    }
  }
}
```

Rule keys become Azure resource names: renaming one replaces the rule. Automation
rule names must be UUIDs in Azure, so the pattern derives a stable UUID from the
workspace and the key.

## Ownership

| Item | Owner |
| --- | --- |
| Log Analytics workspace, retention, Sentinel onboarding | `platform-management` |
| Activity Log and Entra diagnostic settings | `platform-management` |
| Resource-log diagnostic safety net, Defender plans | `platform-policy` (and `platform-management` for its own subscription) |
| CEF forwarder VM | connectivity / Palo Alto owners |
| Data collection endpoints, custom tables, rules and associations for SOC sources | this pattern (`ingestion`) - or `platform-management`, never both for the same rule |
| Connectors, rules, automation rules, watchlists | this pattern (`platform-sentinel`) |
| Playbooks (Logic Apps), ServiceNow SIR integration | Security Operations |
| Sentinel RBAC (Reader, Responder, Contributor) | `platform-authorization` |
| Hunting queries, content hub solutions, UEBA | not in this pattern (see Limits) |

Security Operations owns detection priorities. That is why `baseline_content` is
off by default and shipped as a starting library, not a mandate.

Never manage the same connector or rule from two states. Creating an object
that already exists fails until it is imported, and two states that both own it
will fight over every change.

## Adopting connectors and rules from platform-management

`platform-management` currently owns the Sentinel onboarding, the Defender for
Cloud connector and its two Palo Alto rules through the
`terraform-azurerm-compeer-sentinel` module. Leave the onboarding there. To move
a connector or rule here without recreating it:

1. In this workspace, add the connector or rule to the tfvars with the same name
   (`mdc` for Defender for Cloud, the rule key for a rule).
2. In `platform-management`, remove the object from state **without** destroying
   it: `terraform state rm 'module.management[0].module.sentinel.<address>'`
   (run against the HCP workspace state, using the address from
   `terraform state list`).
3. Import it here:
   `terraform import 'module.sentinel_content[0].azurerm_sentinel_data_connector_azure_security_center.defender_for_cloud["default"]' '<log analytics workspace id>/providers/Microsoft.SecurityInsights/dataConnectors/mdc'`
   (confirm the exact ID with `terraform state show` in platform-management
   before step 2 removes it).
4. Set the matching `sentinel.data_connectors` / rules entry off in
   `platform-management`, then run a plan in both workspaces. Both must be empty
   before you apply either.

Do not skip step 2: turning the flag off in platform-management first destroys
the connector. Review a plan in each workspace before any apply.

## Prerequisites and permissions

- The workspace must already be onboarded. The `platform-sentinel` workspace
  checks `sentinel_onboarding_id` from `platform-management` and stops if it is
  missing.
- Scope the run identity to what each layer needs instead of Contributor on the
  workspace or subscription: Microsoft Sentinel Contributor on the workspace for
  connectors, rules and watchlists; a role that can create data collection
  endpoints and rules and custom tables for `ingestion`; Role Based Access
  Control rights limited to the rule scope when `publisher_principal_ids` is
  used. Confirm the exact role for each tenant-level connector against
  Microsoft's connector documentation before granting it.
- Tenant-level connectors need the run identity to hold the Entra or Defender
  role Microsoft documents for that connector, and the tenant needs the matching
  license. A plan can succeed and the apply still be refused for either reason.
- Automation rules that run playbooks need the Sentinel service principal to hold
  Microsoft Sentinel Automation Contributor on the playbook's resource group.
  Terraform here does not grant it.
- The Defender XDR connector and the product-specific Defender connectors can
  deliver the same alerts twice. A `check` warns (it never blocks) when
  `defender_xdr` is enabled with product-specific connectors, and when two
  enabled incident rules use the same product. Confirm the intended path with
  the SOC.

## Finding template GUIDs

Template rules take the GUID of a template that exists in your workspace. List
them instead of guessing (use the API version your tenant supports):

```bash
az rest --method get \
  --url "https://management.azure.com<workspace resource id>/providers/Microsoft.SecurityInsights/alertRuleTemplates?api-version=2025-09-01" \
  --query "value[].{name:name, kind:kind, displayName:properties.displayName}" -o table
```

## Tests

`terraform test` runs mocked-provider checks (about 80). They cover typed
validation of every enum Microsoft documents, the dependency contract, the
baseline library, automation-rule condition encoding and UUID derivation,
watchlist rows, connector names and telemetry sources. They run on Terraform
1.7.0 and 1.11.4.

What the tests cannot prove: that KQL parses or returns rows, that a connector
is licensed or permitted in your tenant, that a rule's entity-mapping identifier
is accepted for its entity type, or that Azure accepts the content. Run the
baseline and any new rule in a non-production workspace first.

## Limits and extension points

- Not covered: hunting queries, content hub solutions, UEBA/entity analytics,
  TI indicators, AWS and other cloud connectors, playbook (Logic App) creation,
  and diagnostic settings (Activity Log, Entra, resource logs stay with the
  patterns and policies that own them). Add them as sibling files or patterns.
- The provider's `Direct` data collection rule kind is not exposed: it is not
  accepted by every azurerm 4.x release this pattern allows. Pipelines post
  through a data collection endpoint.
- The azurerm fusion rule's `name` is deprecated for provider v5; the provider
  constraint (`< 5.0`) keeps this pattern from adopting v5 unnoticed.
- Built-in anomaly rules cannot be deleted in Azure: removing one from the
  tfvars only disables it.
