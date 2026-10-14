# Workload Key Vault Pattern

WKL-07 / ticket 204117. Independently reusable, and mandatory inside the new
spoke-landing-zone blueprint. It creates one workload vault, its private
endpoint/central DNS-zone group, vault-scoped roles and central audit diagnostics.
It consumes an existing workload RG/subnet and an existing central private zone.

## Fixed Security Baseline

- Azure RBAC, public network access disabled, ACL default Deny and bypass None.
- 90-day soft deletion and purge protection, also in non-production.
- Standard SKU unless an approved HSM-key use case selects premium.
- VM deployment, Azure Disk Encryption and ARM-template secret bypasses off.
- No access policies, secret values, certificates, key material, application
  credentials or automatic deployment-identity data-plane access in state.
- Dedicated vault private endpoint on a non-delegated workload subnet and the
  approved existing privatelink.vaultcore.azure.net zone. No duplicate DNS zone.
- AuditEvent + AllMetrics to the central LAW. No allLogs/category mismatch with
  Compeer's approved diagnostic ownership policy.
- Workload ServicePrincipal/Group readers get Secrets User at this vault only.
  Explicit security/operator groups can receive Secrets Officer. Privileged RBAC
  administration and PIM remain with the authorization owner.

Naming is generated from the shared module: e.g. orders-cus-prod-vault, never
orders-centralus-prod-vault. A caller can supply an approved globally unique
name if required; changing a deployed name is a replacement, not a cosmetic edit.
Supply the shared tags module's output, including the root-owned created_on.

## Using It Separately

```hcl
module "workload_vault" {
  source = "../../patterns/terraform-azurerm-compeer-workload-key-vault"

  resource_group_name        = var.workload_security_rg_name
  location                   = "centralus"
  tenant_id                  = var.tenant_id
  environment                = var.environment
  domain                     = "internal-apps"
  appcode                    = var.approved_appcode
  private_endpoint_subnet_id = var.workload_private_endpoint_subnet_id
  private_dns_zone_id        = var.central_vault_private_dns_zone_id
  log_analytics_workspace_id = var.central_log_analytics_workspace_id
  tags                       = module.tags.tags
  secret_readers = {
    application = { principal_id = var.workload_identity_object_id }
  }
}
```

Set source relative to the actual caller or replace it with the approved,
versioned private-registry release after validation. The reference VNet sample's
registry names/versions are not assumed to publish this new pattern yet.

The caller/provider identity needs vault/PE creation permissions and restricted
role-assignment permission on the workload scope, plus central private-zone
read/join permission. The zone's VNet link and DNS forwarding have ONE external
owner when this pattern is used alone. Diagnostics also need permission to use
the central LAW. No broad Owner grant or cross-subscription role is added here.

## Secure Consumption And Testing

Attach the published workload UAMI to the consuming application. Use its client
ID with Azure SDK ManagedIdentityCredential/DefaultAzureCredential, the returned
vault URI and the configured private DNS path. A Secrets User assignment alone
does not attach an identity to an app or establish network/DNS reachability.

Run `terraform test` for the no-credential suite. The blueprint's real Azure
integration fixture also exercises this separate pattern; its opt-in probe
verifies private DNS and reads a temporary test secret with the workload UAMI.
Live tests require an appropriately networked, authorized runner.

Purge protection is irreversible. Test teardown deletes but NEVER purges the
vault. Use unique test names and account for soft-deleted vaults until their
retention expires. Do not disable production controls to make tests easier.
