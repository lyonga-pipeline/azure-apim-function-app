# Environment Isolation And Promotion

## Decision

Use one thin root per application/environment, each calling an independently
pinned release of the same spoke blueprint. Each root has its own HCP workspace,
state, Azure run identity, provider lockfile and committed non-secret inputs.
All roots can track `main`; do not use environment branches or a pipeline-selected
tfvars file to choose the target deployment.

The former `shared/` adapter did not share state: the environment workspaces
already separated it. Its relative source, and the relative blueprint source
inside it, coupled **code releases**: a merge changed what both roots would load
on their next run. Merely removing the wrapper while keeping a relative blueprint
source would leave that coupling in place.

The active production/non-production roots now call `module.blueprint` directly.
They own only provider configuration, public platform-output reads, contract
guards, stable `created_on` metadata and output assembly. Azure resource logic
remains in the reusable blueprint; no per-environment copy of it is introduced.
The `spoke` variable, optional service/reuse flags and public outputs are unchanged.
The unused `shared/` adapter and its tests have been removed. External consumers
still sourcing that former directory must migrate to a direct, pinned blueprint
call before adopting this checkout. Retained root `moved` declarations support
the same-state transition; removing the directory does not itself migrate state.

## Release Selection

The repository roots independently pin the existing tested catalog snapshot
`99aa3e60e07b7e7fa91ac7a6f4bbbc0ea05f28df` in their own `main.tf`.
They initially select the same release; changing one root's pin does not update
the other. The HTTPS archive includes the catalog's relative child dependencies,
so those dependencies come from the same commit, not the live checkout.

The archive source deliberately avoids this repository's pre-existing incomplete
Git submodule declarations, which make Terraform's recursive Git fetch fail.
Both SHA occurrences in the URL identify the same archive/root directory; update
both when promoting a new commit. This is a native catalog source, **not** a
verified publication of the Compeer HCP edition.

For Compeer, prefer the actual published blueprint's HCP source plus an **exact**
approved `version` in each environment's module block. It is not published yet:
the user supplied the private Azure DevOps `terraform-azurerm-compeer-lz-spoke`
repository's `feat/module` branch for temporary pre-release tests in the local-only
Compeer copy. Per the user, that branch is for temporary local testing only;
actual deployments will use exact HCP registry versions. No Git commit pin is
required for that temporary testing workflow.
Confirm the release address/version and package contents first; base-module pins
alone do not version the blueprint. No unverified registry release has been
invented here, and the Compeer package is not redirected to the native edition.
Keep module source/release selection literal in Git for the supported Core 1.11.4;
do not select it through a runtime tfvars or HCP variable. Registry versions use
the `version` argument; archive sources encode their release in `source` instead.

Normal promotion:

1. Test the blueprint change and publish an immutable module release or record
   its full source commit after merge to `main`.
2. Open a PR updating only the non-production root's pin. Run its tests and HCP
   speculative plan; apply to the approved non-production subscription.
3. Validate private DNS, routing, endpoint access, audit ingestion and the
   application's enabled capabilities. Mock tests are not that live evidence.
4. Open a separate PR updating production to the **same tested release**, retaining
   production-specific inputs and lockfile. Review the production plan and obtain
   approval before apply. Provider upgrades are separate reviewed changes.

The blueprint's source can evolve on `main` without changing either environment's
selected release. Catalog CI tests current source separately from the pinned
environment consumers. Module pins are not recorded by `.terraform.lock.hcl`;
commit each root's module pin and its provider lockfile.

## HCP Workspace Settings

These are required deployment settings, not changes applied to HCP by this PR.
Use the existing workspace for an existing state; do not create an empty second
workspace and apply it against resources the first already owns.

| Setting | Production | Non-production |
| --- | --- | --- |
| VCS branch | `main` | `main` |
| Terraform working directory | `azure-terraform/alz-module-catalog/implementations/workload-lz/workspaces/workload-internal-apps-prod` | `azure-terraform/alz-module-catalog/implementations/workload-lz/workspaces/workload-internal-apps-nonprod` |
| Automatic run triggering | Only files in the production root | Only files in the non-production root |
| Trigger glob | `/azure-terraform/alz-module-catalog/implementations/workload-lz/workspaces/workload-internal-apps-prod/**/*` | `/azure-terraform/alz-module-catalog/implementations/workload-lz/workspaces/workload-internal-apps-nonprod/**/*` |
| State and workspace | Dedicated to this app/production | Dedicated to this app/actual non-production environment |
| Azure credentials | Production-only run identity and approved DNS joins | Separate non-production identity and approved DNS joins |
| Apply | Auto-apply off; production approval/policy gates | Approved non-production policy; no implicit production promotion |

Keep speculative plans enabled and retain PR reviews/required CI. Do not add
live blueprint/module directories or a sibling environment root as
deployment trigger paths: the deployed code is the root's pinned package.
Broad catalog CI is verification, not a deployment trigger. A changed/oversized
VCS file list can still cause HCP to queue extra plans; the fixed source pin and
manual production apply remain protections even then.

Supply `subscription_id`, `tenant_id`, the DNS subscription, authentication and
approved output-read access in each HCP workspace. Use separate production access
policies/variable sets; do not give all environment identities cross-subscription
write permissions. Shared non-secret platform IDs are not shared deployment
credentials. Keep one state owner per Azure resource, including central attachment.

The two committed directories are ticket templates, not one root for an unlimited
number of applications/environments. Before adding another app, test, UAT or np
environment, instantiate another directory with its own pin, inputs, workspace,
identity and root-specific trigger. Do not point several independently promoted
environments at the same root and switch `environment` at runtime. Non-production
retains its existing environment input for compatibility; bind it once per
instantiated root/workspace, never retarget an existing state.

Module pinning isolates **code releases**, not changes to inherited policy, hub
networking or the live `tfe_outputs` values. Those contracts must remain compatible
and independently change-controlled. The existing contract/subscription guards
remain active. Approved explicit `platform_inputs` are still supported, without
copying full platform state or granting broad state access.

## Existing-State Migration

Do not change subscriptions, backend/workspace, resource names, inputs or the
blueprint release at the same time as the wrapper removal. The initial pin is the
existing code snapshot. Each root includes these same-state address moves:

| Previous address | New address |
| --- | --- |
| `module.deployment.module.blueprint` | `module.blueprint` |
| `module.deployment.time_static.deployment_created` | `time_static.deployment_created` |
| `module.deployment.terraform_data.deployment_contract` | `terraform_data.deployment_contract` |

The blueprint move includes its indexed instances and nested resource/module
subtree. The timestamp move preserves `created_on`, avoiding tag churn. Existing
blueprint-internal moves remain inside the selected package. Keep these root
declarations until all relevant existing states have migrated.

Take an access-controlled state backup/version checkpoint, run `terraform init`,
and review a plan in the **existing** HCP workspace. For this refactor alone,
expect address moves with no Azure create/delete/replace actions. Stop and
investigate any unexpected destructive change. No manual `state mv`, import or
cross-workspace ownership transfer is automated by these declarations.
New empty states ignore the old addresses. The committed `enabled=false` examples
remain inert, but changing an already deployed root to false can destroy it;
false is not a pause button.

`test.sh` checks both pinned roots and runs temporary local migration fixtures
using the real `moved.tf` declarations. The fixtures preserve nested counted/map
resource IDs and timestamps with a no-op follow-up plan. They use only Terraform
built-ins and `time_static`, never Azure. A client-state migration plan still
requires separate review.

## Supporting Guidance

- [HashiCorp: separate environment configurations and state](https://developer.hashicorp.com/terraform/tutorials/modules/organize-configuration).
- [HashiCorp: select a module release](https://developer.hashicorp.com/terraform/language/modules/configuration#install-a-specific-version-of-the-module).
- [HashiCorp: workspace VCS settings and trigger patterns](https://developer.hashicorp.com/terraform/cloud-docs/workspaces/settings/vcs#only-trigger-runs-when-files-in-specified-paths-change).
- [HashiCorp: preserve addresses during module refactoring](https://developer.hashicorp.com/terraform/language/modules/develop/refactoring).

This is the recommended fit for Compeer's independent trunk-based promotions,
not a claim that a versioned composition wrapper is universally wrong. A wrapper
can also provide release isolation if each root pins its release independently.
Here the blueprint already provides the reusable boundary, so another live local
wrapper adds release coupling without providing a required resource abstraction.
