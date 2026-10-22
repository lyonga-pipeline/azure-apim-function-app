# Standalone Workload Key Vault Examples

One example root, with a common baseline and four reviewed configurations.
Use a distinct root/state per real application/environment; these variants are
alternative configurations, not four vaults to deploy into the same state.
The parent [module README](../README.md) documents security, ownership and upgrade
contracts. All supplied values are synthetic; neither enable flag is set.

## Choose A Variant

| Variant | Intended use |
| --- | --- |
| [minimal-private](variants/minimal-private.tfvars) | Standard vault, one private endpoint, central audit, application Secrets User. No keys/alerts or extra platform resources. |
| [advanced-private](variants/advanced-private.tfvars) | Premium HSM keys with rotation, two endpoint paths, static-IP/manual-approval examples, scoped crypto/secret groups, three alerts with existing routes, extra audit sinks. |
| [reuse-diagnostics](variants/reuse-diagnostics.tfvars) | Private vault referencing an externally owned exact AuditEvent/AllMetrics setting instead of creating a duplicate. |
| [restricted-public-exception](variants/restricted-public-exception.tfvars) | Non-baseline exception: no endpoint, narrow approved public egress/service-endpoint firewall rules, required RBAC/audit/recovery retained. Azure Policy can still deny it. |

Terraform replaces an entire object/map when another var-file sets it; it does
not deep-merge nested objects. The baseline supplies common tags, identity and
destination context. Each variant supplies a complete replacement object for
the features it changes. Do not stack unrelated variants together.

## Validate Without Deployment

From this directory using Terraform 1.11.4:

```bash
terraform init -backend=false
terraform validate
terraform test -var-file=baseline.tfvars -var-file=variants/minimal-private.tfvars
terraform test -var-file=baseline.tfvars -var-file=variants/advanced-private.tfvars
terraform test -var-file=baseline.tfvars -var-file=variants/reuse-diagnostics.tfvars
terraform test -var-file=baseline.tfvars -var-file=variants/restricted-public-exception.tfvars
```

These tests use real module composition with mocked Azure. They check inert
defaults, the approval gate and enabled configuration. They never deploy Azure.
The repository regression runs all four variants automatically.

## Prepare A Deployment

1. Instantiate an application/environment root with a dedicated backend/HCP
   workspace and identity. Replace the local module source in main.tf with the
   actual approved, exactly versioned registry pattern when published.
2. Replace all sample subscription/tenant/object IDs, resource names, zones,
   subnet/IPAM values, repository/cost metadata and notification destinations.
   Do not commit credentials or secret/private-key material in any var-file.
3. Confirm existing RG/subnet/central DNS links/forwarders/LAW and optional
   routes/audit sinks. Endpoint subnets belong to the provider subscription;
   region/static-IP ownership must match the actual endpoint subnet.
4. Configure approved Azure authentication outside source. Provider registration,
   role-assignment privilege, existing-zone join and audit-export permissions
   must be granted by their owners. Public exceptions/trusted bypass need real
   security approval and any required Azure Policy exemption.
5. For keys, first establish the foundation and validate runner DNS/network and
   key-management permissions. Newly created role assignments may not be usable
   immediately. Do not grant the deployment identity data access automatically.
6. Set enabled=true and deployment_approved=true only in the reviewed real
   environment configuration, then review the plan before apply. These example
   acknowledgements do not replace organizational access/change controls.

```bash
terraform plan -var-file=baseline.tfvars -var-file=variants/minimal-private.tfvars
```

With the committed flags, that plan remains inert. Configure an actual backend
and approved real inputs before any enabled apply; do not use local state for
production. Changing an existing deployment to enabled=false can destroy it.

## Operational Checks

- Verify approved private endpoint connections, intended DNS resolution, effective
  network policies and access from the actual application identity.
- Confirm AuditEvent reaches the central workspace; coordinate Dedicated table
  changes with SOC queries. Additional sink retention/security is externally owned.
- Exercise alert delivery to the existing action group. Decide who responds to
  near-expiry/security events; key rotation policy alone creates no event subscriber.
- Validate consumer key refresh, old-version decryptability and backup/restore.
  A second endpoint is connectivity, not cross-region vault replication.
- Keep purge protection and provider purge-on-destroy flags intact. Secret and
  certificate rotation require separate secure lifecycle automation.

No locks, budgets, subscription onboarding, central LAW/Defender instances or
unrelated compute are introduced by these examples.
