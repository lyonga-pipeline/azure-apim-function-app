# Azure DevOps DevSecOps Pipeline

This folder contains the Azure DevOps pipeline additions for Terraform 2.0 delivery.

Two pipeline entry points are provided:

- `azure-pipelines-devsecops.yml` is the platform or single-workspace pipeline. It keeps a fixed `hcpWorkspace` value and is useful for platform testing.
- `azure-pipelines-workload-devsecops.yml` is the workload pipeline. It resolves the changed Terraform environment root, maps it to the correct HCP workspace, and then runs the same HCP evidence capture.

The deployment pipeline intentionally stays close to the existing working pipeline:

- keep the `Core/Pipelines` Terraform IaC scan template for Terraform validation, linting, and existing quality checks,
- keep the Checkmarx One job shape that already works,
- add PIPE-06/07 HCP plan and policy evidence capture as a second stage. Workload pipelines default to HCP VCS-owned runs; ADO waits for the matching commit run, captures plan/policy evidence, and publishes the evidence back to ADO. API queue mode remains available for platform and smoke-test flows.

OPA policy-code validation and OPA policy-set deployment remain separate because policy rules change on a governance cadence, not on every Terraform deployment. Use `azure-pipelines-opa-policy-code.yml` for OPA policy file changes.

## Current Validated Flow

The validated workload ADO flow is:

1. Run the existing Terraform validation/linting and Checkmarx checks.
2. Resolve the Terraform working directory to the correct HCP workspace.
3. Wait for the HCP VCS-triggered run for the resolved workspace and current commit.
4. Wait for HCP plan JSON, policy checks, and run-task results.
5. Publish full HCP evidence as the `hcp-plan-policy-evidence` artifact.
6. Publish readable HCP evidence summaries into the ADO build.
7. Validate destructive-change acknowledgement from the HCP plan JSON.

HCP remains the Terraform execution and policy evaluation engine. ADO is the review, evidence, and DevSecOps control plane; it does not apply infrastructure in this starter pipeline.

For the platform pipeline, the workspace-resolution step is intentionally skipped and the fixed `hcpWorkspace` variable is used.

## Deployment Pipeline

Use `azure-pipelines-devsecops.yml` for platform stacks or any single-workspace test. Use `azure-pipelines-workload-devsecops.yml` for ClientSync-style workload repositories that have separate roots and workspaces for `sandbox`, `np1`, `np2`, `np3`, and `prod`.

| Stage/job | Purpose |
| --- | --- |
| `SecurityAndQuality` | Existing Terraform and security checks. |
| `templates/terraform-iac-scan.yml@corePipelines` | Existing Terraform validation, linting, and IaC scan template. |
| `CheckmarxOne` | Existing Checkmarx SAST/SCA/IaC scan. |
| `HcpPlanAndPolicyEvidence` | PIPE-06/07 HCP speculative plan, policy-check, and run-task evidence capture. |
| `Validate destructive-change acknowledgement` | Classifies Terraform delete/replace actions and validates PR acknowledgement or change/work item linkage. |

## PIPE Item Coverage

| Item | Coverage | Notes |
| --- | --- | --- |
| `PIPE-03` Checkmarx scan | Yes | Preserves the existing `Checkmarx AST@3` job with `sast`, `sca`, and `iac-security`. Adds a small evidence artifact. |
| `PIPE-06` Speculative plan | Yes, VCS-owned run capture by default | Workload pipelines wait for the HCP VCS-triggered run matching the build commit, then publish plan evidence. API queue mode remains available by setting `queueHcpRunFromAdo` to `true`. |
| `PIPE-07` Policy/run task capture | Yes | Captures HCP `policy-checks` plus task-stage evidence, including run task results and policy evaluations when present. The summary includes policy and run-task failure counts. |
| Destructive-change review | Yes | Classifies delete/replace actions into low, medium, and high impact. Low impact is warning-only. Medium requires PR acknowledgement. High requires PR acknowledgement plus linked work item or change reference. |

PIPE-08 promotion gates and PIPE-09 retention are intentionally not part of the starter pipeline. Promotion control should come first from HCP policy/run-task rules and branch/environment controls.

PIPE-04 Orca is intentionally excluded from this Terraform deployment pipeline unless Compeer confirms its Orca tenant is configured for repo/IaC scanning. If Orca is being used primarily for Azure cloud posture or runtime infrastructure scanning, it should run as a separate cloud-security workflow or HCP run task, not as a Terraform PR lint step.

## Required ADO Configuration

| Name | Type | Purpose |
| --- | --- | --- |
| `Checkmarx-One-Service-Connection` | Service connection | Existing Checkmarx AST service connection. |
| `HCP_TOKEN` | Secret variable | HCP Terraform API token used to read HCP runs, plans, policy checks, and run-task evidence. It also queues runs when `queueHcpRunFromAdo` is `true`. |
| `HCP_OUTPUTS_TOKEN` | Secret variable, optional | Preferred token value to sync into workload workspaces as sensitive `TFE_TOKEN` so Terraform can read upstream `tfe_outputs`. If omitted, the workload pipeline falls back to `HCP_TOKEN`. |
| `System.AccessToken` | Built-in OAuth token | Used to read the ADO PR description and linked work items for destructive-change acknowledgement. Enable "Allow scripts to access the OAuth token" if required by the ADO project settings. |
| `terraformScriptsRoot` | Pipeline variable | Path to the checked-out Terraform automation folder. In this repository it is `azure-terraform`. |
| `hcpOrganization` | Pipeline variable | HCP Terraform organization name. It must match the organization configured in the Terraform `cloud` block for the selected workspace. |
| `hcpWorkspace` | Platform pipeline variable | Fixed HCP Terraform workspace for the platform or any single-workspace test. |
| `terraformWorkingDirectory` | Workload pipeline optional variable | Explicit Terraform root for manual runs, for example `consumer-repos/online-banking/clientsync/environments/np1`. Leave empty for commit-driven inference. |
| `defaultTerraformWorkingDirectory` | Workload pipeline optional variable | Default Terraform root used for broad/shared changes that do not identify exactly one environment root. The ClientSync pilot defaults this to `np1`. |
| `workloadEnvironmentRootPrefix` | Workload pipeline variable | Parent folder used to infer the environment root from changed files when `terraformWorkingDirectory` is empty. |
| `hcpWorkspaceMapFile` | Workload pipeline variable | Source-controlled JSON map file, relative to the repository root. The ClientSync pipeline uses `azure-terraform/pipelines/workspace-maps/clientsync.json`. |
| `hcpWorkspaceMap` | Workload pipeline optional variable | Inline JSON map override. Prefer the source-controlled map for committed workload changes. |
| `hcpWorkspacePrefix` | Workload pipeline optional variable | Fallback naming pattern. If set, the resolver builds `<hcpWorkspacePrefix>-<environment>`. Use only when workspace names follow a reliable convention. |
| `syncTfeOutputReadToken` | Workload pipeline variable | When `true`, syncs a sensitive `TFE_TOKEN` into the resolved HCP workspace. For VCS-owned runs, workspace bootstrap should already provide this variable before the commit lands. |
| `queueHcpRunFromAdo` | Workload/platform pipeline variable | When `false` (workload default), ADO waits for the HCP VCS-triggered run for the same commit. When `true`, ADO queues a plan-only API run and captures that run. |
| `hcpRunDiscoveryAttempts` | Workload pipeline variable | Number of attempts to find the HCP VCS-triggered run when ADO is not queueing one. |
| `hcpRunDiscoverySleepSeconds` | Workload pipeline variable | Seconds between HCP run discovery attempts. |

Set `terraformScriptsRoot` to the path where the Terraform automation folder is checked out. In this repository it is `azure-terraform`. If the ADO implementation repository uses `azure-terraform` as the repository root, set `terraformScriptsRoot` to `.` and adjust pipeline path filters to remove the `azure-terraform/` prefix.

## Workload Workspace Resolution

Workload repositories commonly have one Terraform root per environment and one HCP workspace per root:

| Terraform root | HCP workspace |
| --- | --- |
| `environments/np1` | `lz-workload-<app>-np1` |
| `environments/np2` | `lz-workload-<app>-np2` |
| `environments/np3` | `lz-workload-<app>-np3` |
| `environments/prod` | `lz-workload-<app>-prod` |

The pipeline resolves the workspace in this order:

1. Use `terraformWorkingDirectory` when it is set.
2. Otherwise infer one environment root from changed files under `workloadEnvironmentRootPrefix`.
3. If changed files do not identify exactly one root and `defaultTerraformWorkingDirectory` is set, use that default root.
4. Load the file named by `hcpWorkspaceMapFile`, or use the inline `hcpWorkspaceMap` JSON when no map file is present.
5. Match the root or environment key in the source-controlled map file or inline `hcpWorkspaceMap`.
6. If no map entry exists, use `hcpWorkspacePrefix` and append the environment key.
7. If no prefix is set, fall back to `hcpWorkspace` for legacy single-workspace pipelines.

Recommended enterprise approach: keep the map with the pipeline assets at:

```text
azure-terraform/pipelines/workspace-maps/<workload>.json
```

This keeps the mapping versioned with the pipeline code and avoids relying on manual runtime input. The shared scripts stay generic; workspace names remain workload metadata.

Example file:

```json
{
  "environments/np1": "online-banking-client-sync-devtest",
  "environments/np2": "client-sync-qa-workspace",
  "environments/np3": "ob-clientsync-preprod",
  "environments/prod": "prod-onlinebanking-clientsync"
}
```

The resolver also accepts short environment keys, which is useful when every root follows the same `environments/<env>` shape:

```json
{
  "np1": "online-banking-client-sync-devtest",
  "np2": "client-sync-qa-workspace",
  "np3": "ob-clientsync-preprod",
  "prod": "prod-onlinebanking-clientsync"
}
```

For a ClientSync-style workload repo, set either an exact map:

```yaml
variables:
  workloadEnvironmentRootPrefix: environments
  hcpWorkspaceMap: |
    {
      "environments/np1": "lz-workload-clientsync-np1",
      "environments/np2": "lz-workload-clientsync-np2",
      "environments/np3": "lz-workload-clientsync-np3",
      "environments/prod": "lz-workload-clientsync-prod"
    }
```

or use a naming prefix when workspace names follow the convention exactly:

```yaml
variables:
  workloadEnvironmentRootPrefix: environments
  hcpWorkspacePrefix: lz-workload-clientsync
```

For a monorepo, set `workloadEnvironmentRootPrefix` to the path that contains environment folders, for example:

```yaml
variables:
  workloadEnvironmentRootPrefix: consumer-repos/online-banking/clientsync/environments
  hcpWorkspacePrefix: lz-workload-clientsync
```

When using the default `workloadEnvironmentRootPrefix: environments`, the resolver also supports nested monorepo paths like `consumer-repos/online-banking/clientsync/environments/np1`. In that case, keep the pipeline map keyed by the full path:

```json
{
  "consumer-repos/online-banking/clientsync/environments/np1": "lz-workload-clientsync-np1"
}
```

For the ClientSync pilot in this repository, the map is:

- `azure-terraform/pipelines/workspace-maps/clientsync.json`

The checked-in workload pipeline is configured for the root checkout map:

```yaml
variables:
  defaultTerraformWorkingDirectory: consumer-repos/online-banking/clientsync/environments/np1
  workloadEnvironmentRootPrefix: consumer-repos/online-banking/clientsync/environments
  hcpWorkspaceMapFile: azure-terraform/pipelines/workspace-maps/clientsync.json
```

The starter pipeline captures one HCP workspace per run. For ClientSync training runs, broad pipeline/module changes fall back to `np1` through `defaultTerraformWorkingDirectory`. For release-grade multi-environment validation, split the change, set `terraformWorkingDirectory` for a targeted run, or extend the stage into a matrix.

The HCP workspace must still have its Terraform working directory configured to the same root. The resolver selects the workspace; it does not modify workspace settings. For this repository root, the ClientSync `np1` workspace should use `consumer-repos/online-banking/clientsync/environments/np1`.

For a manual smoke test that only changes pipeline files or the workspace map, set `terraformWorkingDirectory` to `consumer-repos/online-banking/clientsync/environments/np1`. Regular workload commits under an environment folder do not need that runtime input.

For platform stacks that intentionally use one workspace, either keep the legacy fallback:

```yaml
variables:
  terraformWorkingDirectory: .
  hcpWorkspace: lz-platform-shared-root
```

or use a map entry for the root:

```json
{
  ".": "lz-platform-shared-root"
}
```

## HCP Evidence Prerequisites

The HCP evidence stage requires:

- the target root has a mapped HCP workspace with the correct Terraform working directory,
- the HCP workspace has the required Terraform variables, environment variables, and Azure federated credentials,
- policy sets and run tasks have already been attached to the target HCP workspace or project,
- `HCP_TOKEN` is available to the pipeline and can read runs, plans, policy checks, and task stages. It must also be able to queue runs when `queueHcpRunFromAdo` is `true`.
- the token synced as workspace `TFE_TOKEN` can read any upstream workspaces used by `tfe_outputs`.

Workload workspaces default to HCP VCS-owned execution. ADO does not queue a run by default; it waits for the HCP run matching `Build.SourceVersion`, then captures plan JSON, policy checks, and run-task output.

Because the HCP VCS run can start before ADO executes, workspace bootstrap should provision Terraform variables, Azure dynamic credentials, and sensitive environment variables such as `TFE_TOKEN` ahead of time. The ADO sync step is useful for maintenance, but it should not be the only source of required variables for the current VCS-triggered run.

Prefer setting `HCP_OUTPUTS_TOKEN` to a service/team token with read access to the platform-output producer workspaces. If `HCP_OUTPUTS_TOKEN` is not set, the sync step uses `HCP_TOKEN`. The API token used by ADO must also be allowed to manage variables in the target workspace. If that is not available, manually set a sensitive environment variable named `TFE_TOKEN` in the HCP workspace.

For ClientSync `np1`, the producer workspaces referenced by `platform_outputs` must exist in the same HCP organization and have successful applies with the expected outputs:

- `platform-management`
- `platform-connectivity`
- `workload-spoke`

For isolated smoke tests, set `queueHcpRunFromAdo` to `true`. Do that only when HCP VCS automatic triggers are disabled or duplicate API/VCS plan-only runs are acceptable.

ADO does not run `terraform apply` and does not deploy policy sets. It retrieves plan JSON, policy-check output, and run-task output from HCP and publishes those files as pipeline artifacts. By default, raw destroy detection is warning/evidence only because deletes and replacements can be legitimate Terraform outcomes. Failed HCP policy checks and failed HCP run tasks fail the ADO pipeline.

Use `failOnDestroy: 'true'` only for workspaces where every delete or replacement must be blocked automatically. For most teams, the better enterprise pattern is to publish destructive-change evidence from ADO and enforce approval through HCP policy enforcement, HCP run tasks, manual apply, or protected ADO environments.

## Destructive-Change Review

The deployment pipeline uses `destructive-change-policy.json` and `validate-destructive-change-approval.sh` to classify delete/replace actions from HCP `plan.json`.

| Type | Examples | Pipeline action |
| --- | --- | --- |
| Low / expected replacement | Diagnostic settings, generated child resources, private endpoint NIC-style changes | Warn only and publish evidence. |
| Medium impact | App service slots, private endpoints, role assignments, subnet associations, private DNS links | Require PR acknowledgement using the `Destroy resource` change type. |
| High impact | Storage accounts, Key Vaults, SQL resources, VNets/subnets, production identity/security/platform resources | Require PR acknowledgement plus a linked work item, change ticket, or approved change reference. |

The acknowledgement check recognizes either of these PR patterns:

```text
- [x] Destroy resource
```

```text
Change type: Destroy resource
```

For high-impact destructive changes, one of the following must also exist:

- an ADO work item linked to the PR,
- `CHANGE_APPROVAL_REFERENCE` set by a controlled pipeline variable,
- a PR description reference such as `CHG12345`, `CRQ12345`, `AB#12345`, `Change ticket: ...`, or `Approval reference: ...`.

The validator writes these files into the `hcp-plan-policy-evidence` artifact:

- `destructive-changes.json`
- `destructive-change-approval.json`
- `destructive-change-approval.md`
- `destructive-change-violations.txt`

This gives Compeer a practical compromise: legitimate delete/recreate actions do not create noise by default, but unacknowledged medium or high impact destructive plans are caught before review/approval.

By default, `destructiveChangeEnforceOnlyOnPr` is `true`, so PR-template acknowledgement is enforced only during PR validation builds. Branch builds on `main` or `develop` still publish destructive-change evidence, but they do not fail simply because there is no PR body to inspect.

## OPA Policy-Code Pipeline

Use `azure-pipelines-opa-policy-code.yml` as the separate OPA policy-code validation pipeline. It runs only when OPA policy files or HCP policy-scope catalog files change and validates Rego with `opa fmt` and `opa test`.

The same pipeline now has a second protected branch stage, `HcpOpaPolicySetDeployment`, that plans and deploys the HCP OPA policy set from `azure-terraform/hcp/control-plane`. By default, it bundles the Rego policy plus required JSON data into one individual HCP OPA policy and attaches that policy to the policy set, so the stage does not need a VCS OAuth token ID or versioned policy-set entitlement.

Deployment behavior:

- PR builds run validation only.
- `develop` branch builds run Terraform init/validate/plan and publish deployment evidence.
- `main` branch builds run Terraform init/validate/plan/apply and publish deployment evidence.

Required variables/secrets for the deployment stage:

| Name | Type | Purpose |
| --- | --- | --- |
| `HCP_TOKEN` | Secret variable | HCP Terraform token used by the `tfe` provider. |
| `HCP_ORGANIZATION` | Pipeline variable | HCP Terraform organization that owns the policy set. |
| `HCP_PROJECT_SCOPES` | Optional pipeline variable | Comma-separated HCP project names to attach the policy set to. Leave unset to keep it unattached to projects. |
| `HCP_WORKSPACE_SCOPES` | Optional pipeline variable | Comma-separated HCP workspace names to attach the policy set to. Leave unset to keep it unattached to workspaces. |
| `HCP_EXCLUDED_WORKSPACES` | Optional pipeline variable | Comma-separated HCP workspace names to exclude from the policy set. |
| `HCP_POLICY_CONTENT_MODE` | Optional pipeline variable | Defaults to `individual`, which creates one OPA policy and attaches it to the policy set. Use `none` to only attach an existing policy set, or `slug` only when the HCP organization supports uploaded/versioned policy sets. |

The stage intentionally avoids `HCP_OAUTH_TOKEN_ID` and `POLICY_REPO_IDENTIFIER`. Those are only needed for VCS-backed HCP policy sets. In organizations with many VCS connections, discovering the right `ot-...` value is ambiguous.

If an HCP run shows `OPA policies errored`, that means the policy failed to compile or evaluate, not that a normal guardrail failed. Normal guardrail results should appear as mandatory failures or advisory warnings with the policy messages. The deployment stage runs `opa check` and a small `opa eval` against the bundled policy before Terraform plan/apply so bundle shape errors are caught in ADO first.

Example runtime scope:

```text
HCP_PROJECT_SCOPES=lyonga-project
```

Leaving `HCP_PROJECT_SCOPES` and `HCP_WORKSPACE_SCOPES` empty is valid. The pipeline will create or update the policy and policy set, then leave the policy set unattached.

The local validation job still pins the downloaded OPA binary through `opaVersion`, but the HCP policy-set deployment does not pin `policy_tool_version`. HCP Terraform only accepts policy tool versions available in the target organization, so leaving it unset avoids apply failures when the local validation version is newer than HCP's supported runtime list.

For test/free HCP organizations, keep `HCP_POLICY_CONTENT_MODE` unset so it defaults to `individual`. Some plans allow policy sets and individual policies but have a limit of `0` uploaded/versioned policy sets, so `slug` mode fails in those organizations.

The deployable catalog is `azure-terraform/hcp/policy-scope-catalog.yaml`. Update its `source_control`, `project_scopes`, `workspace_scopes`, and `excluded_workspaces` values before enabling the `main` apply path. The `policy-scope-catalog.example.yaml` file remains as a safe reference model.
