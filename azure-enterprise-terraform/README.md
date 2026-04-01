# Azure Landing Zone Terraform Blueprint

This directory is the authoritative infrastructure entry point for the repo. It replaces the old single-root demo with a security-first, landing-zone-oriented Terraform layout intended for financial-services workloads.

For the assessment framework, remediation-vs-rebuild guidance, official Azure and Terraform references, and a review of how this repo currently aligns with those patterns, see [`RECOMMENDATIONS.md`](./RECOMMENDATIONS.md).

For a stack-by-stack explanation of the active v2 enterprise pattern, see [`terraform/README-v2.md`](./terraform/README-v2.md).

## Goals

- Split infrastructure by blast radius and operating model, not by convenience.
- Keep security and governance above workload speed.
- Make local testing possible in a personal subscription while preserving patterns that scale to a client estate.
- Use remote state, management groups, RBAC, policy, hub-spoke networking, private DNS, diagnostics, drift detection, and CI scanning as first-class concerns.

## Repo Layout

```text
azure-enterprise-terraform/
  terraform/
    global/
      subscriptions/
      management-groups/
      policy/
      role-assignments/
      platform-connectivity-shared/      # optional, only for a truly shared corporate hub
      platform-management-shared/        # optional, only for a truly shared global management plane
    modules/
      action-group/
      app-configuration/
      apim/
      azuredevops_repo/
      container_registry/
      diagnostics-1/
      function_app/
      keyvault/
      log-analytics/
      management_groups/
      monitoring-baseline/
      network/
      platform-tags/
      private-dns/
      private-endpoint/
      recovery-services-vault/
      resource_group/
      role-assignments/
      service-bus/
      sql-database/
      state-storage/
      storage/
      user-assigned-identity/
      vnet-hub/
      vnet-peering/
      vnet-spoke/
    stacks/
      dev/
        platform-v2/
          connectivity/
          management/
          identity/
        workload-v2/
          finserv-api/
      test/
        platform-v2/
          connectivity/
          management/
          identity/
        workload-v2/
          finserv-api/
      prod/
        platform-v2/
          connectivity/
          management/
          identity/
        workload-v2/
          finserv-api/
```

`terraform/global` plus `terraform/stacks/<env>/platform-v2` and `terraform/stacks/<env>/workload-v2` are the intended deployment model. In this repo, `dev` is the only active validated environment. `test` and `prod` are placeholder scaffolds that exist to show the full enterprise layout during review.

Deprecated reference roots:

- `terraform/stacks/dev/platform`
- `terraform/stacks/dev/workloads`
- `terraform/stacks/prod/*`
- `terraform/global/resource_grouping`

Do not extend those deprecated roots. The active control plane is under `terraform/global`, and the old dev-scoped `platform-v2/subscriptions` and `platform-v2/governance` roots have been retired in favor of `global/subscriptions`, `global/management-groups`, `global/policy`, and `global/role-assignments`.

## Pattern Status

Current landing-zone alignment for the active v2 path:

- implemented: separate company-wide roots for `global/subscriptions`, `global/management-groups`, `global/policy`, and `global/role-assignments`
- implemented: environment-scoped roots for `connectivity`, `management`, `identity`, and workload composition
- implemented: placeholder `test` and `prod` v2 environment trees so the target multi-environment shape is visible during review
- implemented: a dedicated global `subscriptions` root to keep subscription inventory separate from governance
- implemented: explicit subscription targeting per active stack through root provider configuration
- implemented: active v2 stacks validate their explicit `subscription_id` against the central `subscriptions` remote state
- implemented: hub-spoke networking, hub peering, central Private DNS, and private endpoints
- implemented: shared identity and CMK services through `platform-v2/identity`
- implemented: OIDC-capable plan/drift workflows and backend Azure AD auth
- implemented: ALZ-lite governance baseline for regions, enterprise tags, public IP denial, and private-by-default platform services in landing zones
- partial: governance baseline is still smaller than a full enterprise ALZ policy estate and does not yet model diagnostics `deployIfNotExists`, policy exemptions, or broader compliance initiatives
- partial: only the `dev` v2 estate is active and validated; `test` and `prod` are placeholders that still need environment-specific configuration and promotion
- partial: modules are custom and ALZ/AVM-aligned in structure, but not yet AVM-backed across the board

## Deployment Order

Apply stacks in this order:

1. `terraform/global/subscriptions`
2. `terraform/global/management-groups`
3. `terraform/global/policy`
4. `terraform/global/role-assignments`
5. `terraform/stacks/dev/platform-v2/connectivity`
6. `terraform/stacks/dev/platform-v2/management`
7. `terraform/stacks/dev/platform-v2/identity`
8. `terraform/stacks/dev/workload-v2/finserv-api`

For `test` and `prod`, follow the same ordering after replacing the placeholder environment values with real subscription ids, backend keys, and naming inputs.

This order matters because:

- this is apply order, not just plan order; remote-state consumers need upstream stacks to have already written outputs into state;
- the shared backend must exist before remote state can be used;
- subscription ownership and placement should be declared before management-group associations consume them;
- management groups, global policy, and global RBAC should exist before platform and workloads are deployed;
- connectivity and private DNS are shared dependencies for private endpoints;
- management provides central logging and recovery services used by workloads;
- identity provides shared managed identities and customer-managed keys consumed by workloads.
- the active dev demo is pinned to two existing subscriptions:
  - platform-v2 stacks use `65ac2b14-e13a-40a0-bb50-93359232816e`
  - workload-v2 stacks use `ce792f64-9e63-483b-8136-a2538b764f3d`
- a fuller enterprise rollout would normally split `connectivity`, `management`, and `identity` into separate subscriptions even though this dev demo intentionally collapses them into the shared platform subscription.

## Stack Purpose

### Shared backend prerequisite

This repo assumes the Azure Storage backend already exists in the shared state account `demotest822e`.

Key design choices:

- the backend is a platform prerequisite, not a per-project stack;
- each root keeps its own backend key;
- Azure AD auth is used via `use_azuread_auth = true`;
- backend access is controlled with Blob data-plane RBAC rather than storage keys in CI.

### `global/subscriptions`

Creates a dedicated source of truth for subscription isolation.

This stack is responsible for:

- declaring which existing subscription belongs to which management group branch;
- providing a single output map for governance and the active stacks to consume;
- keeping the demo environment explicit about which subscription is the shared platform subscription and which is the workload subscription.

This dev blueprint intentionally assumes the client already has existing subscriptions. The active pattern is existing-subscriptions-only.

Existing-subscription path:

```hcl
platform = {
  management_group_key      = "platform"
  existing_subscription_id  = "65ac2b14-e13a-40a0-bb50-93359232816e"
  subscription_display_name = "FinServ Platform"
}
```

Notes:

- the active `dev.tfvars` maps all platform-v2 stacks to one existing platform subscription and workload-v2 to one existing nonprod workload subscription;
- this keeps the dev demo low-friction while preserving the landing-zone stack boundaries;
- the `test` and `prod` environment trees are present as placeholders only; replace their placeholder subscription ids and stack config before treating them as deployable roots.

## Ownership Matrix

Use this as the default decision table for where resources belong.

| Stack | Subscription Role | Owns VNet? | VNet Role | Owns Subnets? | Subnet Roles |
| --- | --- | --- | --- | --- | --- |
| `global/subscriptions` | catalog only | No | None | No | None |
| `global/management-groups` | tenant and management-group scope | No | None | No | None |
| `global/policy` | tenant and management-group scope | No | None | No | None |
| `global/role-assignments` | tenant and management-group scope | No | None | No | None |
| `platform-v2/connectivity` | shared platform subscription in this demo | Yes | Hub | Yes | Hub service subnets, firewall/gateway/private-dns-linking support |
| `platform-v2/management` | shared platform subscription in this demo | No | None by default | No | None by default |
| `platform-v2/identity` | shared platform subscription in this demo | Yes | Shared-services spoke | Yes | Shared identity-service subnets |
| `workload-v2/finserv-api` | nonprod workload subscription | Yes | Workload spoke | Yes | `app`, `integration`, `data`, `private-endpoints`, optional `apim` |

## Environment Scaffolding

This repo now shows a full three-environment landing-zone picture:

- `dev`: active demo environment and the only path currently validated end to end
- `test`: placeholder nonprod environment that can stand in for QA or stage in client reviews
- `prod`: placeholder production environment

Only `dev` should be planned or applied without first replacing placeholder values in the other environments.

### How to choose a subscription

- In this demo, use the shared platform subscription for `connectivity`, `management`, and `identity`.
- Use the separate nonprod workload subscription for `workload-v2/finserv-api`.
- In a fuller enterprise rollout, split hub networking, monitoring, and shared identity services into separate subscriptions even though the dev demo intentionally collapses them.

### How to choose a VNet or subnet

- Use the hub VNet from `platform-v2/connectivity` only for central network services.
- Give each workload its own spoke VNet in its workload stack.
- Within a workload spoke, use subnet purpose rather than picking ad hoc:
  - `app`: app-tier compute or front-end resources
  - `integration`: Function/App Service VNet integration and outbound app connectivity
  - `data`: data-tier workloads that need tighter isolation
  - `private-endpoints`: all private endpoints
  - `apim`: dedicated APIM subnet when APIM is enabled

## Subscription Targeting Pattern

The active v2 stacks do not auto-derive provider targets from remote state.

Instead, they use this pattern:

- each root stack keeps an explicit `subscription_id`;
- the `global/subscriptions` stack is the catalog of approved subscription ownership;
- active v2 stacks validate their explicit `subscription_id` against that catalog before planning.

This is safer than deriving provider targets implicitly from remote state because it keeps execution scope obvious while still preventing drift between stack config and the central landing-zone subscription map.

The active global and dev v2 roots also set `skip_provider_registration = true` in the root `azurerm` provider. That is intentional. In enterprise estates, provider registration is usually handled centrally or pre-registered once by a platform admin, rather than giving every deployment identity permission to register resource providers on demand.

### Resource Provider Registration

Azure Resource Providers are the control-plane namespaces behind services such as networking, Key Vault, App Service, and SQL.

In practice, that means:

- a subscription must be registered for a namespace before Azure will let you create resources from that namespace;
- with `skip_provider_registration = true`, Terraform will not try to register providers on the fly;
- if a namespace is missing, apply fails with `MissingSubscriptionRegistration` until a platform admin registers it once for that subscription.

This repo intentionally uses that pattern because it is the better enterprise tradeoff:

- deployments stay predictable and do not mutate subscription-wide settings as a side effect;
- deployer identities do not need broad `*/register/action` permissions;
- provider registration can be handled once by platform administrators per subscription.

Common registrations used by the active roots include:

| Stack | Common provider namespaces |
| --- | --- |
| `platform-v2/connectivity` | `Microsoft.Network` |
| `platform-v2/management` | `Microsoft.OperationalInsights`, `microsoft.insights`, `Microsoft.RecoveryServices`, `Microsoft.Storage` |
| `platform-v2/identity` | `Microsoft.Network`, `Microsoft.KeyVault`, `Microsoft.ManagedIdentity`, `microsoft.insights` |
| `workload-v2/finserv-api` | `Microsoft.Network`, `Microsoft.Storage`, `Microsoft.KeyVault`, `Microsoft.ManagedIdentity`, `Microsoft.AppConfiguration`, `Microsoft.ServiceBus`, `Microsoft.Sql`, `Microsoft.ContainerRegistry`, `Microsoft.Web`, `Microsoft.ApiManagement`, `Microsoft.OperationalInsights`, `microsoft.insights` |

Register them at subscription scope before first deployment, for example:

```bash
az provider register --namespace Microsoft.Network --subscription 65ac2b14-e13a-40a0-bb50-93359232816e --wait
```

Use the Azure Portal path `Subscriptions -> <subscription> -> Resource providers` if you prefer a UI workflow.

## Ownership Boundaries

Do not apply the same ownership pattern to subscriptions, management groups, and resource groups. They serve different control-plane purposes.

### Subscriptions

Use a central catalog and validation pattern:

- the `global/subscriptions` stack is the source of truth;
- active stacks keep an explicit `subscription_id`;
- active stacks validate that `subscription_id` against the catalog before planning.

This keeps execution scope obvious while still enforcing central control.

### Management Groups

Manage these centrally under `terraform/global`.

- management groups are tenant-level governance objects;
- subscription-to-management-group associations belong in governance;
- workload and platform stacks should not each manage or reinterpret management-group structure.

The right pattern is central ownership, not per-stack validation.

### Resource Groups

Usually keep resource groups owned by the stack that deploys into them.

- connectivity owns its hub resource group;
- management owns its monitoring resource group;
- identity owns its shared-services resource group;
- workloads own their workload resource groups.

Only shared resource groups, such as the Terraform state resource group, should be treated as cross-stack dependencies and referenced through remote state or shared configuration.

### `global/management-groups`

Creates:

- enterprise management-group hierarchy
- subscription placement associations based on the global subscriptions catalog

This is the company-wide control plane for Azure hierarchy and should not be duplicated per environment.

### `global/policy`

Creates:

- global custom policy definitions
- a platform foundation initiative
- a landing-zone baseline initiative
- management-group policy assignments for `platform`, `nonprod`, and `prod`

This is where enterprise Azure Policy belongs. It is intentionally ALZ-lite today and should be expanded with exemptions and `deployIfNotExists` diagnostics over time.

### `global/role-assignments`

Creates:

- company-wide RBAC assignments at management-group scope for platform deployers, security readers, and workload deployment identities

This keeps high-scope RBAC out of workload stacks.

Use this stack when you want inherited access across a management-group branch,
such as a platform deployer that can manage the full `platform` branch,
dedicated deployer identities for `security` and `prod`, or a read-only
identity for `prod`.

Reader assignments do not allow deployments. With the current hierarchy,
`platform` is the parent of `security`, so a platform deployer assigned at
`platform` inherits write access into `security`. That same assignment does not
grant write access to `prod`, because `prod` sits under the separate
`landing_zones` branch.

The `nonprod`, `security`, and `prod` deployer identities in this stack receive both
`Contributor` and `User Access Administrator` so they can deploy resources and
also manage Terraform-driven RBAC assignments inside those branches.

### `platform-v2/connectivity`

Creates:

- hub virtual network
- shared hub subnets
- optional Azure Firewall
- central Private DNS zones
- hub VNet links to those Private DNS zones

This is where you swap in a third-party firewall or DNS design if the client standard is Palo Alto, Cisco Umbrella, or another centralized service. The module structure stays valid even if the egress implementation changes.

Keep connectivity here at environment/platform scope unless the organization operates one truly shared corporate hub across environments. In that special case, use a dedicated shared-global connectivity root such as `terraform/global/platform-connectivity-shared`.

### `platform-v2/management`

Creates:

- Log Analytics workspace
- diagnostics archive storage account
- action group
- Recovery Services Vault
- subscription activity log export baseline

This is the starting point for Sentinel, Defender integrations, alert routing, and operational observability standardization.

### `platform-v2/identity`

Creates a shared-services identity landing zone that demonstrates:

- an isolated identity subscription target
- a dedicated shared-services VNet
- hub peering back to central connectivity
- central Private DNS linking
- a premium Key Vault for shared service encryption
- shared user-assigned identities for workload and platform service integration
- a shared HSM-backed CMK
- diagnostics to the central management workspace

This layer is where shared managed identities, shared keys, and other identity-adjacent platform services should live instead of being recreated in every workload stack.

### `workload-v2/finserv-api`

Creates a sample workload stack that demonstrates:

- workload resource group
- spoke VNet
- restrictive NSG defaults
- VNet peering to the hub
- Private DNS zone links from connectivity state
- shared identity and CMK consumption from the identity stack by default
- storage account
- workload-local Key Vault for application secrets
- App Configuration
- Service Bus
- optional Azure SQL
- optional Azure Container Registry
- Linux Function App
- private endpoints for common PaaS services
- optional API Management
- optional Azure DevOps repository/project resources

Some services are behind toggles because APIM, Premium App Service plans, SQL, and ACR can be expensive for personal testing.

### Runtime Identity and RBAC Baseline

The active workload pattern now treats Azure managed identity and RBAC as the Azure equivalent of an AWS application role:

- `workload-v2/finserv-api` runs the Function App with a user-assigned managed identity, not a separate implicit runtime identity.
- the same workload identity is reused for App Configuration, Service Bus CMK access, and runtime RBAC assignments.
- baseline workload RBAC now includes:
  - `Key Vault Secrets User` on the workload Key Vault
  - `Storage Blob Data Contributor` on the workload storage account
  - optional `Storage Queue Data Contributor`
  - `App Configuration Data Reader` when App Configuration is enabled
  - `Azure Service Bus Data Sender` and `Azure Service Bus Data Receiver` when Service Bus is enabled

Expand the baseline in the workload root instead of changing shared modules:

- `additional_workload_role_assignments` in [`terraform/stacks/dev/workload-v2/finserv-api/variables.tf`](./terraform/stacks/dev/workload-v2/finserv-api/variables.tf) lets you add more runtime RBAC assignments while defaulting `principal_id` to the workload identity.

There is still one deliberate exception: the Function App host storage path still uses the storage account access key for compatibility, even though the workload identity now also has storage RBAC for application data access.

For legacy demo stacks:

- the reusable Linux VM module now supports managed identities by default
- the legacy `dev/workloads` stack gives the demo VM a system-assigned identity
- when `create_demo_vm = true`, the stack can apply a small baseline access set and be extended with `demo_vm_additional_role_assignments`

That gives you an expandable template without making every stack invent its own identity pattern.

## Tagging Guidance

Based on the governance screenshots you shared, the blueprint standardizes around these core tags:

- `env`
- `application`
- `created_by`
- `bt_owner`
- `source_repo`
- `tf_workspace`
- `recovery`
- `cost_center`
- `data_classification`
- `compliance_boundary`

### About `creation_date` and `last_modified`

Do not manage those two tags naively in Terraform:

- `creation_date` should be written once and then treated as immutable.
- `last_modified` changes on every apply, which creates permanent drift if Terraform owns it directly.

Recommended patterns:

- write them outside Terraform with an automation function;
- or store them in a CMDB/inventory system instead of tags;
- or set them once and use `lifecycle.ignore_changes = [tags["creation_date"], tags["last_modified"]]` in resource-specific cases if you truly need them as tags.

## Remote State Pattern

Each active v2 stack uses an empty backend block:

```hcl
terraform {
  backend "azurerm" {}
}
```

Initialize with a per-stack backend config:

```bash
terraform init -backend-config=backend.hcl
```

Example `backend.hcl`:

```hcl
resource_group_name  = "rg-tfstate-dev"
storage_account_name = "demotest822e"
container_name       = "deploy-container"
key                  = "stacks/dev/platform-v2/connectivity.tfstate"
subscription_id      = "00000000-0000-0000-0000-000000000004"
use_azuread_auth     = true
```

### Backend Best Practices

- Keep one backend storage account per environment or trust boundary.
- Keep one backend key per stack.
- Never share a single key across multiple stacks.
- Prefer Azure AD auth over shared keys and SAS tokens.
- When `use_azuread_auth = true`, grant the CI identity `Storage Blob Data Contributor` on the backend storage account or container.
- Restrict write access to CI identities. Humans should generally be read-only.
- Keep the backend resource group and storage account in a platform-owned scope, not inside a workload stack.
- Enable blob versioning, blob soft delete, and container soft delete so state can be recovered.
- Enable infrastructure encryption and minimum TLS 1.2 on the backend account.
- Treat the backend account as critical infrastructure: lock it down with RBAC, diagnostics, and backup-friendly retention.

### Backend Layout Guidance

For personal testing, this repo uses:

- storage account `demotest822e`
- container `deploy-container`
- backend subscription `00000000-0000-0000-0000-000000000004`
- one blob key per v2 stack

For enterprise use, prefer:

- a dedicated backend storage account per environment or landing-zone trust boundary
- a separate backend subscription or shared platform subscription when required by policy
- separate keys for each global root, each platform stack, and each workload stack
- private endpoints plus self-hosted runners if the backend must not be publicly reachable

### Backend Security Rules

- Do not commit real `backend.hcl` files with environment-specific secrets or private endpoints.
- Commit `.terraform.lock.hcl` for every active stack.
- Do not commit `.terraform/`, `tfplan`, local state, or crash logs.
- Do not let workload identities write platform state.
- If using GitHub-hosted runners, keep backend public access enabled only when justified and IP restriction is not practical.
- If backend public access is disabled, run Terraform from a self-hosted runner in an allowed network path.

### Provider and Subscription Isolation

Each active v2 stack now declares its own `subscription_id` and uses that in the root `azurerm` provider. That means:

- global governance roots can run in a platform execution subscription while targeting management groups
- `connectivity`, `management`, `identity`, and workload stacks can each deploy into separate subscriptions
- backend state can stay centralized in a different subscription from the resource deployment target

This is the minimum practical subscription-isolation pattern for an enterprise Azure landing zone when each stack is a separate Terraform root.

## State Locking, Blob Leasing, and Concurrency

Azure Blob backends use blob leases for state locking. One state key can have only one active writer at a time.

Operational rules:

- lease contention is expected when two runs hit the same key
- do not disable locking
- do not share a state key across unrelated stacks
- serialize applies with GitHub Actions `concurrency`
- use separate keys to reduce contention
- only run `terraform force-unlock` when you have confirmed the lock is stale

### Lease Handling Runbook

Use this order of operations when a stack appears locked:

1. Confirm whether another `plan` or `apply` is still running for the same stack.
2. Check the matching GitHub Actions run, local shell session, or CI agent before touching the lock.
3. Retry after the active run finishes; a waiting lease is normal behavior.
4. Use `terraform force-unlock <LOCK_ID>` only if the owning process is gone and you are certain no real apply is in flight.
5. After unlock, run `terraform plan` first. Do not go straight to apply.

### Concurrency Best Practices

- One concurrency group per stack path is the correct minimum control.
- Allow different stacks to plan in parallel when they use different backend keys.
- Do not run parallel applies against the same stack.
- Prefer reviewed-plan artifacts over recomputing a fresh plan during apply.
- Keep `cancel-in-progress: false` for applies so one run does not interrupt another mid-change.
- Be careful with scheduled drift jobs and manual applies against the same key. They should not overlap.

This repo’s plan/apply workflow uses:

- one concurrency group per stack path
- artifacted plans
- explicit manual dispatch for apply

## Drift Detection

`/.github/workflows/terraform-drift.yml` is OIDC-based and does the following:

- runs `terraform plan -detailed-exitcode`
- uploads the generated plan
- publishes the plan to the workflow summary
- opens or updates a GitHub issue when drift is detected
- closes the issue when drift clears

### Drift Operating Model

- schedule drift nightly or multiple times per day for critical stacks
- start with workload stacks, then add platform stacks
- keep `ARM_SKIP_PROVIDER_REGISTRATION=true` for drift jobs with read-only identities
- review drift before applying; do not auto-apply platform changes blindly
- treat repeated drift as a control failure, not just a pipeline nuisance

### Common Azure Drift Sources

- manual portal edits
- policy remediation tasks
- RBAC changes made outside Terraform
- diagnostic settings added by other tooling
- private endpoint or DNS changes made by networking teams
- eventual consistency around management groups, RBAC, and policy assignments

### Drift Triage Guidance

- If drift is expected and temporary, document it and close the gap quickly.
- If drift is caused by policy remediation, decide whether Terraform or policy should own the setting.
- If drift is caused by manual changes, import the resource or remove the manual process.
- If drift repeats on every run, fix the module contract instead of suppressing the symptom.

## Validation, Testing, and Scanning

`/.github/workflows/terraform-ci.yml` runs:

- `terraform fmt -check -recursive`
- `terraform init -backend=false`
- `terraform validate`
- Checkov with SARIF upload

### Minimum PR Gate

Every pull request should pass:

- formatting
- initialization without backend access
- validation
- static security scanning
- at least one stack plan before merge for changed stacks

### Recommended Test Layers

Use more than one type of test:

- `terraform validate` for syntax and provider schema
- `terraform test` for native module contract tests
- Checkov and TFLint for static analysis
- Terratest or Kitchen-Terraform for real Azure integration tests
- contract tests for cross-stack remote-state outputs
- smoke tests after apply for workload reachability and DNS resolution

### Native Terraform Test Guidance

As modules stabilize, add `tests/*.tftest.hcl` for:

- required variable validation
- output contracts
- expected plan-time assertions for secure defaults
- module behavior toggles such as optional SQL, APIM, or Azure DevOps resources

### Azure Integration Test Guidance

For integration tests in a real subscription:

- use ephemeral resource groups where possible
- avoid running destructive tests against shared platform stacks
- run connectivity and private-endpoint assertions after apply
- verify DNS resolution from inside an allowed network path, not just from the public internet
- test RBAC-managed services with managed identities, not only with deployer credentials

### Recommended Additions

- TFLint with Azure rules
- policy-as-code tests for custom policy definitions and initiatives
- `terraform providers lock` refresh in a controlled upgrade process
- a smoke test workflow that verifies private DNS, Function App reachability, and Key Vault resolution

## Plan and Apply Workflow

`/.github/workflows/terraform-plan-apply.yml` is:

- OIDC-based
- manually triggered
- parameterized by `stack_path`, `backend_config_path`, and `var_file`
- designed to produce a plan artifact before optional apply

### Production Workflow Controls

- use GitHub Environments with required reviewers for apply
- split nonprod and prod identities
- give platform pipelines higher scope than workload pipelines
- give workload pipelines only the scopes they actually deploy to
- avoid `Owner`; prefer `Contributor` plus `User Access Administrator` only where RBAC is managed
- protect the default branch and require CI before merge
- apply only the reviewed plan artifact, not a fresh recalculated plan
- keep production apply on a short allowlist of maintainers

### Azure Pipeline Identity Guidance

- Use OIDC federation from GitHub Actions to Entra ID.
- Keep one identity for platform stacks and separate identities for workload stacks where possible.
- Grant state access explicitly to the CI identity.
- If Terraform manages role assignments, the pipeline identity also needs the correct RBAC scope to do so.
- For drift-only jobs, use a read-oriented identity and keep provider registration disabled.

## Azure-Specific Best Practices

### Management Groups and Subscriptions

- Keep platform subscriptions separate from workload subscriptions.
- Associate subscriptions into management groups through code.
- Put governance at management group scope, not resource-group scope.

### Networking

- Use hub-spoke, not flat shared VNets.
- Centralize Private DNS zones.
- Link every spoke that hosts private-endpoint consumers.
- Keep a dedicated private-endpoints subnet.
- Add restrictive NSGs intentionally; do not rely on defaults.
- Document every service tag exception you allow.

### Key Vault

- Keep `public_network_access_enabled = false` unless there is a deliberate exception.
- Use RBAC mode by default.
- Do not auto-grant the deployer Key Vault Administrator everywhere.
- Plan for purge protection and name reuse constraints.

### Storage

- Set `allow_nested_items_to_be_public = false`.
- Set `min_tls_version = "TLS1_2"`.
- Enable versioning and retention.
- Be deliberate about `shared_access_key_enabled`; some services still require it.

### Functions and App Service

- Prefer Premium plans when private networking is required.
- Validate Function App storage dependencies when disabling public access.
- Keep `https_only = true`.
- Disable FTP/FTPS.
- Use Application Insights via workspace-based mode.

### APIM

- Treat APIM as optional in personal testing because of cost.
- For enterprise deployment, give APIM its own subnet and explicit NSG rules.
- If you move to internal mode, validate all required management ports and health probe requirements.

### SQL, Service Bus, App Configuration

- Disable public network access by default.
- Add private endpoints and DNS.
- Use managed identity and RBAC where possible.
- Avoid connection strings and local auth unless the service integration requires them.

## Azure DevOps Notes

The Azure DevOps module supports optional project and repository creation plus minimum-reviewer policy. It assumes you provide Azure DevOps authentication through provider configuration or environment variables.

Recommended environment variables:

- `AZDO_ORG_SERVICE_URL`
- `AZDO_PERSONAL_ACCESS_TOKEN`

Keep Azure DevOps resources optional so Terraform can still validate in environments that do not use Azure DevOps.

## Local Usage

Example flow for a stack:

```bash
cd terraform/stacks/dev/platform-v2/connectivity
cp backend.hcl.example backend.hcl
cp dev.tfvars.example dev.tfvars
terraform init -backend-config=backend.hcl
terraform plan -var-file=dev.tfvars
terraform apply -var-file=dev.tfvars
```

Use the same flow for every stack.

## Cost Notes for Personal Testing

Reasonable low-cost path:

- use the precreated shared backend in `demotest822e`
- deploy `global/subscriptions`
- deploy `global/management-groups`, `global/policy`, and `global/role-assignments`
- deploy `platform-v2/connectivity` without Azure Firewall
- deploy `platform-v2/management`
- deploy `workload-v2/finserv-api` with:
  - `enable_apim = false`
  - `enable_sql = false`
  - `enable_container_registry = false`
  - `enable_azuredevops = false`

Turn on APIM, SQL, ACR, and Premium egress controls only after the base pattern is working.

## Migration Notes

The old top-level Terraform monolith has been removed.

If you want to migrate the remaining legacy Terraform folders:

1. stop using `terraform/stacks/dev/platform`, `terraform/stacks/dev/workloads`, `terraform/stacks/prod/*`, and `terraform/global/*` in CI
2. move any missing state outputs into the new `terraform/stacks/dev/*-v2/*`
3. import surviving resources into the new v2 stacks where necessary
4. delete or archive the legacy stacks after state is fully migrated

## Validation Status

The active v2 stacks were validated locally. Before taking this to a client, rerun:

- `terraform fmt -recursive`
- `terraform init -backend=false`
- `terraform validate`
- `terraform test` for any stack or module with native tests
- `tflint`
- `checkov`
- reviewed `terraform plan` output for every changed stack
- scheduled drift detection for active stacks
- nonprod plans for every active v2 stack

Do that in your personal subscription first, then tighten any remaining provider or SKU details before recommending it to a client.
