# Dev Platform V2 Management

## Purpose

This stack is the shared monitoring and operations layer for the `dev`
platform plane.

It creates the common observability and recovery services that other platform
and workload stacks send telemetry into.

For the broader design rationale, see `terraform/README-v2.md`.

## Why This Stack Exists

- Monitoring and diagnostics should be consistent across the estate.
- Platform teams need a standard place for logs, alerts, and recovery services.
- Workload teams should not each invent their own management plane.

## What This Stack Owns

- the management resource group
- the shared Log Analytics workspace
- the diagnostics archive storage account
- the operations action group
- the Recovery Services vault
- the subscription monitoring baseline

## What It Reads From

- direct environment inputs such as names, retention, and location
- optional `global/subscriptions` remote state for subscription validation

This stack does not need connectivity or identity state to stand up its core
services.

## Subscription Catalog Mapping

This sample stack should use the `management` entry in `global/subscriptions`.

That means:

- `subscription_catalog_entry_key = "management"`
- `subscription_id` should eventually match the real management subscription ID
  recorded in the central catalog

Why this matters:

- the management stack is a shared platform service
- it should validate against the management platform subscription, not a
  generic shared platform placeholder
- this keeps shared monitoring and operations services in their own
  subscription boundary

## Main Inputs

- `subscription_id`
  - Makes the management subscription explicit and supports validation.
- `location`
  - Defines where the shared management services live.
- naming inputs
  - Keep the workspace, storage, and action-group naming consistent.
- retention and archive settings
  - Control how long telemetry is kept and where it is stored.

## What This Stack Does

- creates the management resource group
- creates the shared Log Analytics workspace
- creates the diagnostics archive storage account
- optionally creates a Log Analytics storage-insights connection
- creates the operations action group
- creates the Recovery Services vault
- enables a monitoring baseline for subscription activity logs

## What Other Stacks Use From It

- `platform-v2/identity`
  - Sends Key Vault diagnostics into the shared workspace.
- `workload-v2/*`
  - Send platform and workload telemetry into the shared management plane.

This stack is the main shared destination for monitoring data in the
environment.

## Main Building Blocks

- `module "tags"`
- `module "resource_group"`
- `module "workspace"`
  - Creates the shared Log Analytics workspace.
- `module "diagnostics_archive"`
  - Creates archive storage for diagnostics.
- `azurerm_log_analytics_storage_insights.diagnostics_archive`
  - Optionally connects the workspace to archive storage.
- `module "action_group"`
  - Creates the shared alert target.
- `module "recovery_services_vault"`
- `module "monitoring_baseline"`
  - Enables the subscription activity-log baseline.

## Code Map

- `data.tf`
  - Optional subscription catalog validation.
- `main.tf`
  - Creates the shared management services.
- `outputs.tf`
  - Publishes workspace, storage, and alerting outputs.
- `dev.tfvars`
  - Supplies environment-specific settings such as names and retention.

## How To Extend It

- Add shared alert rules or diagnostics standards here if they apply to many
  stacks.
- Keep workload-specific alerts in workload stacks unless the organization
  wants a standard rule for every landing zone.
- Publish any shared management destination as an output so downstream stacks
  can consume it cleanly.

## Best-Practice Notes

This is the right place for environment-shared monitoring and operations
services.

It gives engineers one clear answer to an important onboarding question:
"Where should platform and workload telemetry go?" In this pattern, it comes
here.
