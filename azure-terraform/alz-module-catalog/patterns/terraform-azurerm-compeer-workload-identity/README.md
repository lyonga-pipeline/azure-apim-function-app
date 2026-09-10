# Workload Identity

Secret-less **federated workload identities** for CI/CD and IaC automation —
design-doc **Phase 4 Step 7-8** ("Managed Identity Framework" / "Federated
Workload Identity Framework"). One Entra app registration + service principal per
automation identity, trusted through OIDC federated credentials, with the Azure
roles the SP holds.

## What is Terraform-managed here

| Object | Module / resource |
|---|---|
| App registration | `terraform-azuread-compeer-ad-application` |
| Service principal | `terraform-azuread-compeer-service-principal` |
| Federated identity credentials (OIDC trust rules) | `azuread_application_federated_identity_credential` |
| SP role assignments (SP → built-in role → scope) | `azurerm_role_assignment` |

**No client secrets or passwords** are created. Each federated credential pins an
exact `issuer` + `subject` + `audience`; an app registration allows at most **20**
federated credentials, so the platform uses a few SPs split by permission scope
rather than one per workspace.

`user-assigned managed identities` for Azure-hosted workloads are created by the
`platform-identity` / `workload-spoke` patterns, not here — this pattern is for
identities that authenticate from *outside* Azure (HCP Terraform, GitHub Actions,
Azure DevOps).

## What is deliberately NOT here

`operational_contracts` — the HCP variable-set wiring that consumes
`application_client_ids`, the GitHub/ADO side of any service connection, and the
periodic "no secrets were added" attestation.

## Outputs

`application_client_ids` → HCP `TFC_AZURE_RUN_CLIENT_ID` per workspace.
`service_principal_object_ids` → RBAC on any other scope.
