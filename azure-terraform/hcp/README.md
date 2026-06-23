# HCP Terraform Operating Model

HCP Terraform is the control plane for the net-new landing-zone path. It owns state, workspace execution, variable sets, policy attachment, drift detection, and run evidence for the new landing zone.

## HCP Project Layout

| HCP project | Workspaces | Policy posture |
| --- | --- | --- |
| `ce-lz-governance` | global governance, management-group guardrails, Azure Policy baseline | Advisory first, blocking after pilot |
| `ce-lz-platform` | connectivity, management, identity | Advisory first, blocking after pilot |
| `ce-lz-workloads` | approved pilot and future app workload workspaces | Advisory first, targeted blocking by environment |
| `legacy-observe` | read-only observation or future migration workspaces | No blocking policy attachment by default |

## Workspace Naming

Use names that identify ownership, platform layer, environment, and workload.

Examples:

- `lz-gov-global`
- `lz-platform-connectivity-np`
- `lz-platform-management-np`
- `lz-platform-identity-np`
- `lz-workload-online-banking-np1`

## Workspace Standards

Each workspace should have:

- a single lifecycle boundary,
- VCS connection to the exact Terraform root,
- remote state enabled in HCP,
- drift detection enabled,
- speculative plans on pull requests,
- variable sets for shared values,
- no secrets committed in `tfvars`,
- and policy sets attached according to the workspace's landing-zone phase.

## Variable Sets

| Variable set | Scope | Contents |
| --- | --- | --- |
| `vs-azure-tenant` | Net-new landing-zone projects | `tenant_id`, default Azure region list, tenant metadata |
| `vs-azure-auth-nonprod` | Non-prod workspaces | Sensitive workload identity credentials or federated auth settings |
| `vs-azure-auth-prod` | Prod workspaces | Separate sensitive auth values with tighter access |
| `vs-lz-standards` | Net-new landing-zone projects | Required tags, allowed locations, naming hints, policy mode |
| `vs-platform-shared-np` | Workload non-prod workspaces | Approved shared IDs for Log Analytics, action groups, DNS zones, and subnets |
| `vs-platform-shared-prod` | Workload prod workspaces | Production shared IDs with stricter access |

Prefer HCP workspace outputs or approved variable sets for shared platform IDs. If Azure data lookups are used, keep them in the root composition and make the lookup criteria explicit.

## Policy Attachment

Attach OPA/Sentinel-style policy sets only to net-new landing-zone HCP projects at first. Do not attach blocking policies to legacy/current projects until remediation readiness is confirmed.

Recommended stages:

1. `advisory`: reports violations, does not block.
2. `soft-block`: blocks only high-risk controls in non-prod with manual override.
3. `blocking`: enforces approved controls for net-new production landing-zone workspaces.
4. `legacy-extension`: applies selected controls to remediated existing projects.

## Access Model

Use least-privilege HCP teams:

- `ce-lz-admin`: workspace administration and policy management.
- `ce-lz-platform-operators`: plan/apply for platform workspaces.
- `app-team-operators`: plan/apply for assigned workload workspaces.
- `security-governance-readers`: read access to plans, policy checks, and drift evidence.

Human access changes should be approved through the identity/access process. Terraform should manage stable role assignments at Azure scope when the scope and principal are durable.
