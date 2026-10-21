# Explicit Live Azure Integration Tests

NOT run by ordinary terraform test or pull-request CI. This fixture creates
billable RGs, a hub/spoke, LAW, private DNS, private endpoints, identity,
purge-protected vault, optional Application Insights/operational alerts and a
private Blob account in an explicitly supplied isolated subscription.
It never reads client platform state or deploys into client hub/DNS resources.
The fixture now composes foundation and central attachment as separate modules:
the spoke publishes its contract, and the attachment module creates both
peerings and the required VNet/DNS links. Only this isolated fixture uses one
test state for both stages; production uses separate platform-owned states.

Prerequisites: Terraform >=1.11.4 and <2, Azure CLI, Python 3, approved authentication and
resource-provider/role-assignment permissions in the isolated test subscription.
Use a persistent/protected runner workspace so a failed cleanup does not lose
the Terraform state. Do not run simultaneously with the same run_id/state.

```bash
export ALLOW_LIVE_AZURE_TEST=true
export TF_VAR_test_subscription_id='<ISOLATED_TEST_SUBSCRIPTION_UUID>'
export TF_VAR_run_id='<UNIQUE_APPROVED_RUN_ID>'
export TF_VAR_cost_center='<APPROVED_TEST_COST_CENTER>'
export TF_VAR_created_on='<YYYY-MM-DD>'
# Optional approved Phase 2 extension coverage (otherwise held/omitted):
# export TF_VAR_enable_optional_operations_test=true
# export TF_VAR_notification_email='<APPROVED_TEST_NOTIFICATION_EMAIL>'
bash run.sh
```

The driver applies actual modules, checks Azure's observed vault security,
subnet defaults, NSG denies, route associations, reciprocal Connected peerings,
approved PE/DNS-zone registration, central AuditEvent diagnostics and scoped
workload identity role, then destroys resources even if a check fails. It does
not mistake configured Terraform outputs for a successful Azure write path.
It checks specific inspection routes and disabled gateway BGP propagation.
When explicitly enabled, it also reads actual Entra-only Application Insights,
alert destinations. No budgets are created. Optional Blob security/recovery/
diagnostic properties are checked independently.
It also checks that referenced action groups are enabled. When run against
approved contracts referencing existing telemetry, workspace/authentication
checks still apply but sampling remains with that resource's owner. The isolated
fixture exercises creation; mocked root tests exercise cross-subscription ID
reuse. Neither is evidence of shared client permissions or real alert delivery.
enable_blob_storage_test defaults true; false explicitly omits that capability.
enable_vault_test defaults true. Set it false for an approved secretless-spoke
test; the fixture then requests no vault DNS link. Vault DNS/secret probes and
temporary vault operator access must also be off. The driver rejects that
contradiction before deployment, and the verifier still checks the network,
peerings and every enabled storage/telemetry capability.

The verifier checks root storage AllMetrics, Blob read/write/delete plus
Transaction metrics, and vault AuditEvent plus AllMetrics. It checks declared
external diagnostic IDs against observed settings and rejects duplicate
coverage. Existing failed-request alerts must be enabled, scoped to the right
component and have valid metric criteria and actual action-group destinations;
their approved severity remains with the existing owner. The isolated fixture
does not pretend to create an external owner's existing resources. Reuse variants
are mock-composed from the real examples; actual shared-resource permissions and
configuration must be verified in a staging environment before client adoption.
No VM or backup vault is created. VM backup enrollment is mock-tested against
approved existing IDs; testing actual backup/restore requires a separately
approved VM and policy in staging. Blob data-plane access is not claimed by the
control-plane verifier.

## Private DNS And Secret Access

The default run is CONTROL PLANE ONLY. A public CI runner cannot prove private
data-plane access. For private checks, arrange an approved runner path into the
new test spoke and its private DNS zone. Do not attach a second zone of the same
name to an existing VNet or mutate client DNS to make the test pass.

For a retained/manual test, use terraform apply with allow_live_deployment=true,
arrange the approved private-runner attachment, run the probe, then destroy.
Terraform's local state must be protected and preserved throughout that process.

```bash
terraform output -json spoke | python3 verify_spoke.py --private-dns
```

For a FULL secret round trip, use an isolated Azure runner with the blueprint's
workload UAMI attached. Its managed-identity endpoint must be available. The
runner's SEPARATE Azure CLI operator identity needs the explicitly opted-in
temporary vault-scoped Secrets Officer role (enable_secret_probe_operator=true;
set runner_principal_type appropriately). Install the optional SDK requirements:

```bash
python3 -m pip install -r requirements.txt
terraform output -json spoke | python3 verify_spoke.py --secret-probe
```

The probe writes a uniquely named temporary secret using AzureCliCredential,
reads it using ManagedIdentityCredential with the exact workload UAMI client ID,
and deletes it in a finally block. It never falls back to operator credentials
for the read, reads application secrets, prints token/secret values, stores
secret values in Terraform state, or purges a vault/secret. RBAC propagation is
retried within a bounded timeout. Failed deletion requires operator cleanup.

For a pre-arranged private runner, VERIFY_PRIVATE_DNS=true and
VERIFY_SECRET_ACCESS=true make run.sh require those checks before cleanup.
The driver does NOT create a VM, attach identities to existing client machines,
or establish a runner path automatically.

Network prefixes in this fixture are TEST-ONLY defaults, not Compeer IPAM
allocations. The approved next-hop fixture is not an operating firewall: this
test does not claim to prove inspected egress, on-prem routing, workload app
behavior, Defender/flow-log policy convergence or production readiness.

Purge-protected vaults remain soft-deleted after cleanup. Use unique run IDs;
do not weaken purge protection or silently purge old vaults. On cleanup failure,
preserve the protected state and use test_run tags to inventory remaining RGs.

Offline harness checks: `python3 -m unittest -v test_verify_spoke.py`.
