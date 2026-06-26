# Pull Request Checklist

## Change Type

- [ ] New landing zone or platform component
- [ ] Workload landing zone or application pattern
- [ ] Terraform module change
- [ ] Policy or governance change
- [ ] Pipeline or bootstrap change
- [ ] Drift remediation
- [ ] Exception update
- [ ] Destroy resource

## Scope

Impacted HCP workspace(s):

Impacted Azure subscription/resource group(s):

Impacted module version(s):

Target environment:

## Evidence

- [ ] Terraform fmt/validate passed
- [ ] TFLint or equivalent IaC quality check passed
- [ ] Checkmarx/IaC security scan evidence attached or linked
- [ ] HCP speculative plan evidence attached or linked
- [ ] HCP policy/run task result evidence attached or linked
- [ ] Drift status reviewed
- [ ] Exception status reviewed

## Destructive Change Review

Complete this section when the plan includes delete or replace actions.

Planned delete/replace impact:

Reason the destructive action is expected:

Linked work item/change/approval reference:

Rollback or recovery notes:

## Readiness

- [ ] No unintended impact to current/legacy landing-zone projects
- [ ] Required owners/reviewers are included
- [ ] Required variables, secrets, subscription IDs, subnet IDs, and policy modes are known
- [ ] Documentation or README updates are included when behavior changes
