# Platform Observability

**PHASE2 NEW:** v5 OBS-04, OBS-06, OBS-07, NET-30 and PLT-05. Routed KQL/native metric alerts, AMA/DCR/DCE associations, optional Change Tracking, Azure Workbooks and TCP Connection Monitor.

## Ownership And Defaults

Reuse RG, LAW, action groups, existing VM UAMIs, DCRs and Watcher. install_agent=false plus existing_agent_confirmed=true reuses AMA without adopting its extension. Empty maps create nothing. DCRs remain owned by platform-management; do not duplicate associations.

## Inputs And Outputs

| Input | Default | Purpose |
| --- | --- | --- |
| `resource_group_name / log_analytics_workspace_id` | `Required` | Existing management/monitoring scope. |
| `location / tags` | `centralus / {}` | Region and owner/cost metadata. |
| `action_group_ids` | `[]` | Existing notification routes; required for enabled alerts. |
| `log_alerts` | `{}` | Reviewed KQL, severity, evaluation/window and threshold. |
| `metric_alerts` | `{}` | Native metrics, resource scopes, thresholds and dimensions; existing action-group routes are required. |
| `agents` | `{}` | VM/UAMI, OS, DCR IDs and create/reuse/readiness flags. |
| `workbooks` | `{}` | Stable UUID and version-controlled workbook JSON. |
| `connection_monitors` | `{}` | Existing Watcher, source VM, TCP target and readiness. |


The typed [variables.tf](variables.tf) defines every nested setting and guard; [outputs.tf](outputs.tf) exposes resource IDs by caller-stable key. Required context inputs do not create resources. Optional collections are opt-in. Use an existing approved resource group; this pattern does not own its lifecycle.

Use the existing management [workspace root](../../implementations/platform-lz/workspaces/platform-management) and its `phase2.tfvars.example` for alert/workbook inputs. VM agent inputs belong to directory/connector/external-identity owners; Connection Monitor belongs to connectivity. See the [engineering map](../../implementations/phase2/ENGINEERING-HANDOFF.md). Examples are synthetic, not production approvals. Replace all synthetic values and review ownership before enabling any entry.

```hcl
module "phase2" {
  source = "../../patterns/terraform-azurerm-compeer-platform-observability"
  resource_group_name = "platform-cus-prod-monitor-rg"
  log_analytics_workspace_id = "/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/monitor-rg/providers/Microsoft.OperationalInsights/workspaces/platform-law"
  # Supply required context and explicitly approved capability maps from tfvars.
  # In deployment roots, promote to a reviewed pinned registry version.
}
```

## Operational Contract

KQL must match real tables; actual query validation is enabled. Missing heartbeat is not service health. AMA does not onboard MDE. Change Tracking and network probes require approved agent/DCR/network readiness. All live alert delivery and ingestion must be tested.

For private AMA ingestion set `private_ingestion_enabled=true`, an existing `data_collection_endpoint_id` and `private_link_scope_ready=true` only after verifying DCE region, DCR destinations, AMPLS membership and DNS. By default this pattern owns the VM's single `configurationAccessEndpoint` association. If another state owns it, set `manage_endpoint_association=false` and `external_endpoint_association_confirmed=true`; never overwrite that association from two states. Inventory additionally requires `change_tracking_dcr_key` naming an associated, inventory-specific DCR.

The pilot demonstrates ExpressRoute `BgpAvailability`, firewall ILB `DipAvailability` and LAW `ExportFailed` metrics. Confirm actual dimensions/availability and tune thresholds before enabling. ILB probe status is not full Palo Alto/HA health; Panorama/SolarWinds and a real traffic-path test remain required. Native metrics provide an alert route when log ingestion itself is unavailable.

References: [private AMA/DCE configuration](https://learn.microsoft.com/en-us/azure/azure-monitor/fundamentals/private-link-vm-kubernetes), [LAW export metrics](https://learn.microsoft.com/en-us/azure/azure-monitor/reference/supported-metrics/microsoft-operationalinsights-workspaces-metrics).

[Phase 2 readiness and acceptance](../../implementations/phase2/RUNBOOKS.md) distinguishes mock coverage from live acceptance. No ARM management locks are added. Terraform >=1.11.4 is required; provider constraints are in [terraform.tf](terraform.tf).

## Validation

```sh
terraform init -backend=false
terraform validate
terraform test
```

Mocks test enabled/disabled composition and guards without Azure/HCP credentials. They do not prove live permissions, service quotas, network/data delivery or business compliance. Run real speculative plans and approved pilot checks before release.
