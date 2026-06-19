# Landing Zone IaC Patterns

This directory contains the Cloud Enablement reference implementation for Compeer's net-new Azure landing zone deployment path.

The intent is to establish a clean way to deploy cloud foundations with Terraform before broad rollout. Existing projects are not forced into the new controls until they are remediated, imported, and ready for the same enforcement model.

## Operating Model

Terraform boundaries are organized into three ownership layers:

| Layer | Purpose | Typical owner | Terraform boundary |
| --- | --- | --- | --- |
| Global governance | Tenant/subscription placement, policy baseline, naming/tag standards, broad guardrails | Cloud Enablement / Governance | Low-change governance workspaces |
| Shared environment platform | Hub networking, DNS, observability, shared identity, security services | Cloud Enablement / Platform operations | Environment platform workspaces |
| Workload landing zones | Spoke network placement and application-owned Azure resources | Application teams with Cloud Enablement standards | Per-app/per-environment workspaces |

Reusable modules stay narrow. Landing-zone roots compose modules into approved enterprise patterns.

## What Belongs Here

- Management group and subscription placement scaffolding.
- Platform connectivity roots for hub/spoke networking, Private DNS zones, NSGs, route tables, and network attachments.
- Platform management roots for Log Analytics, action groups, and shared observability.
- Platform identity roots for platform identities, Key Vault, access assignment, and diagnostics.
- Workload spoke roots that show how app environments consume shared platform outputs and deploy application resources.

## What Does Not Belong Here

- CI/CD templates. Those remain outside this update because Compeer already has templates to integrate.
- App-specific business deployment logic.
- Hidden subscription, subnet, DNS, or Log Analytics inference inside reusable modules.
- Policy enforcement against current projects before those projects are ready for remediation.

## Baseline Sequence

1. Configure HCP projects, workspaces, teams, variable sets, and net-new policy sets.
2. Deploy global governance and Azure Policy definitions with enforcement scoped to the net-new landing zone.
3. Deploy shared platform workspaces for connectivity, management, and identity.
4. Deploy one pilot workload spoke using the new module catalog and explicit platform outputs.
5. Turn drift detection, exception tracking, and policy reporting into recurring operational routines.
6. Extend the model to additional workloads after the pilot proves the workflow.

## Policy Isolation

Policy-as-code and Azure Policy should attach to net-new landing-zone workspaces first. Existing projects remain outside blocking policy scope until they have:

- an agreed remediation backlog,
- known state ownership,
- import or migration plans,
- exception records where needed,
- and a validated promotion path into the new model.

This protects current delivery while still giving the new landing zone the right enterprise guardrails from day one.

