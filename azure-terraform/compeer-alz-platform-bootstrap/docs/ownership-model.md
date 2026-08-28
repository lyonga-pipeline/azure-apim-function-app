# Control-plane ownership model

| Object | Ownership |
|---|---|
| Existing ADO organization | Reference only |
| Existing ADO project | Reference only |
| Existing project-level branch policies | Inherit; do not duplicate |
| Existing workload repos/bootstrap | Out of scope |
| New ALZ platform repo(s) | `stacks/ado` |
| New ALZ OPA repo | `stacks/ado` |
| ALZ validation build definitions | `stacks/ado` |
| Existing HCP organization | Reference only |
| Existing HCP VCS OAuth connection | Reference only |
| Existing HCP agent pools | Reference only |
| New ALZ HCP project | `stacks/hcp` |
| New ALZ platform workspaces | `stacks/hcp` |
| New ALZ variable sets / associations | `stacks/hcp` |
| New ALZ OPA policy set | `stacks/hcp` |

Terraform-managed control-plane configuration is changed through PRs. Direct UI changes are break-glass only and must be reconciled back into code or intentionally reverted. Critical repositories, project, and workspaces use `prevent_destroy`.
