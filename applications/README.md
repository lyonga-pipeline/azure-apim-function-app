# Applications

These application roots demonstrate the direct-consumer model for the shared Azure Terraform catalog.

## Design Approach

- Each application root calls `../../azure-terraform/modules/*` directly.
- There are no local wrapper modules between the application and the shared catalog.
- Environment-specific inputs live in `environments/np1.tfvars`, `environments/np2.tfvars`, `environments/np3.tfvars`, and `environments/prod.tfvars`.
- The root module may derive consistent names from `application_name` and `environment`, but workload configuration is supplied through tfvars.

## Included Application Roots

- `web-portal`
  Covers web workload composition with App Service, Key Vault, storage, CMK, private endpoints, private DNS, RBAC, and diagnostics.
- `integration-platform`
  Covers function-based and batch/event-driven integration patterns with Function App, Container Instances, Event Grid, storage primitives, NAT, and private connectivity.
- `ops-sql-platform`
  Covers VM-based operations and database patterns with NICs, NSGs, route tables, NAT, load balancer, Windows VM attachments, SQL Server, private SQL access, and operational controls.
- `api-analytics-platform`
  Covers API edge and analytics patterns with Application Gateway, API Management, APIM content modules, Key Vault certificates, Managed HSM, storage, Synapse, and diagnostics.

## Usage

Initialize and validate an application root:

```bash
terraform -chdir=applications/web-portal init
terraform -chdir=applications/web-portal validate
```

Plan a specific environment:

```bash
terraform -chdir=applications/web-portal plan -var-file=environments/np1.tfvars
```
