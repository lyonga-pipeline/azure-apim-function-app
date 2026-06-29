# Azure DevOps DevSecOps Pipeline

This folder contains the Azure DevOps pipeline additions for Terraform 2.0 delivery.

The deployment pipeline intentionally stays close to the existing working pipeline:

- keep the `Core/Pipelines` Terraform IaC scan template for Terraform validation, linting, and existing quality checks,
- keep the Checkmarx One job shape that already works,
- add PIPE-06/07 HCP evidence capture as a second stage.

OPA policy-code validation remains separate because policy rules change on a governance cadence, not on every Terraform deployment. Use `azure-pipelines-opa-policy-code.yml` for OPA policy file changes.

## Deployment Pipeline

Use `azure-pipelines-devsecops.yml` as the starting Terraform deployment pipeline in the ADO implementation repo.

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
| `PIPE-06` Speculative plan | Yes, retrieve mode | Retrieves the HCP run/plan for the configured workspace and commit. This assumes HCP VCS integration creates the speculative run from the ADO PR/branch. |
| `PIPE-07` Policy/run task capture | Yes | Captures HCP `policy-checks` plus task-stage evidence, including run task results and policy evaluations when present. |
| Destructive-change review | Yes | Classifies delete/replace actions into low, medium, and high impact. Low impact is warning-only. Medium requires PR acknowledgement. High requires PR acknowledgement plus linked work item or change reference. |

PIPE-08 promotion gates and PIPE-09 retention are intentionally not part of the starter pipeline. Promotion control should come first from HCP policy/run-task rules and branch/environment controls.

PIPE-04 Orca is intentionally excluded from this Terraform deployment pipeline unless Compeer confirms its Orca tenant is configured for repo/IaC scanning. If Orca is being used primarily for Azure cloud posture or runtime infrastructure scanning, it should run as a separate cloud-security workflow or HCP run task, not as a Terraform PR lint step.

## Required ADO Configuration

| Name | Type | Purpose |
| --- | --- | --- |
| `Checkmarx-One-Service-Connection` | Service connection | Existing Checkmarx AST service connection. |
| `HCP_TOKEN` | Secret variable | HCP Terraform API token used to read HCP run, plan, policy-check, and run-task evidence. |
| `System.AccessToken` | Built-in OAuth token | Used to read the ADO PR description and linked work items for destructive-change acknowledgement. Enable "Allow scripts to access the OAuth token" if required by the ADO project settings. |

Set `terraformScriptsRoot` to the path where the Terraform automation folder is checked out. In this repository it is `azure-terraform`. If the ADO implementation repository uses `azure-terraform` as the repository root, set `terraformScriptsRoot` to `.` and adjust pipeline path filters to remove the `azure-terraform/` prefix.

## HCP Evidence Prerequisites

The HCP evidence stage requires:

- the target root has a mapped HCP workspace,
- HCP VCS integration is creating runs for the same ADO branch/commit,
- policy sets and run tasks have already been attached to the target HCP workspace or project,
- `HCP_TOKEN` is available to the pipeline.

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
