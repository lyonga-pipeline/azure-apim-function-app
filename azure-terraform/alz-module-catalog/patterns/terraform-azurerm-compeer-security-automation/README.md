# Secret Rotation Delivery

**PHASE2 NEW:** v5 SEC-13. Named-secret Key Vault near-expiry event subscriptions, constrained handler RBAC, retry and identity-backed dead-letter delivery.

## Ownership And Defaults

Reuse an existing vault-owned system topic with SystemAssigned identity, deployed Function, its managed identity and existing dead-letter container. Set create_system_topic=true only when no topic exists and this state will own its lifecycle; the pattern then creates a topic/identity for that vault. secret_rotations={} creates nothing. No secret values or Function keys are Terraform inputs.

## Inputs And Outputs

| Input | Default | Purpose |
| --- | --- | --- |
| `tags` | `{}` | Approved governance tags for newly created topics; reused topics remain untouched. |
| `secret_rotations` | `{}` | Per-vault named secret allowlist, handler ID/identity, existing dead-letter destination and acceptance evidence. |
| `secret_rotations.*.create_system_topic` | `false` | Reuse and verify a topic by default; true creates one only when no topic exists. |
| `secret_rotations.*.topic_principal_id` | `null` | Required for reused topics and checked against the actual source topic identity. |
| `secret_rotations.*.system_topic_location` | `centralus` | Match the source vault region when creating a topic. |


The typed [variables.tf](variables.tf) defines every nested setting and guard; [outputs.tf](outputs.tf) exposes resource IDs by caller-stable key. Required context inputs do not create resources. Optional collections are opt-in. Use an existing approved resource group; this pattern does not own its lifecycle.

Use the independent [workspace root](../../implementations/platform-lz/workspaces/platform-security-automation) and its `terraform.tfvars.example` for inert defaults. `approved-pilot.tfvars.example` demonstrates explicit reference values, not production approvals. Replace all synthetic values and review ownership before enabling any entry.

```hcl
module "phase2" {
  source = "../../patterns/terraform-azurerm-compeer-security-automation"
  secret_rotations = {} # Requires a real tested handler before enabling.
  # Supply required context and explicitly approved capability maps from tfvars.
  # In deployment roots, promote to a reviewed pinned registry version.
}
```

## Operational Contract

This is delivery infrastructure, not a generic credential-rotation engine. The acceptance-tested handler must update the backing service AND vault, validate event source/allowlist, tolerate retries, protect concurrency and verify rollback/consumer behavior. Verify topic/vault linkage, actual topic principal, endpoint reachability and dead-letter writes. Handler-specific backing-service permissions remain with the service owner.

[Phase 2 readiness and acceptance](../../implementations/phase2/RUNBOOKS.md) distinguishes mock coverage from live acceptance. No ARM management locks are added. Terraform >=1.11.4 is required; provider constraints are in [terraform.tf](terraform.tf).

## Validation

```sh
terraform init -backend=false
terraform validate
terraform test
```

Mocks test enabled/disabled composition and guards without Azure/HCP credentials. They do not prove live permissions, service quotas, network/data delivery or business compliance. Run real speculative plans and approved pilot checks before release.
