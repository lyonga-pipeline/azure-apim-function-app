# Secrets Lifecycle Deployment Root

Deploy this root in independent production and nonproduction HCP workspaces. It
creates the rotation platform and optionally assigns reviewed governance policies.
It does not replace the legacy security-automation handler wiring automatically.

See the [implementation and onboarding guide](../../../../patterns/terraform-azurerm-compeer-secret-lifecycle/README.md)
for architecture, adapters, security boundaries, triggers, policy ownership,
new-vault enrollment, consumer contracts, recovery and acceptance tests.

Start from `terraform.tfvars.example`. Supply real approved subscription/network/
DNS/monitoring/identity data; all example assets are disabled. Create infrastructure
first with `package_path=null`, validate private networking, then supply the
Linux-built Python 3.12 ZIP and apply from an Azure-authenticated private runner.

The Azure provider uses federated environment credentials. The optional CLI ZIP
deployment also requires the runner's Azure CLI login, Contributor deployment
access and private SCM connectivity. HCP hosted workers without network access
cannot deploy to these private endpoints; use an approved self-hosted agent.

Contributor cannot create the required Azure RBAC assignments. Supply a constrained
RBAC deployment role through the platform approval process. Directory Graph consent
and application ownership are separate IAM operations, not Azure Contributor rights.

No Key Vault secret values belong in tfvars, Terraform outputs or state. The registry
contains identifiers and lifecycle policy, not credentials. New vaults require
explicit registry approval plus workload-owned enrollment; creation alone does not
grant a central worker permission to rotate every secret.
