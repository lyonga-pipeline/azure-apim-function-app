# Policy-Owned Private Endpoint DNS

## Ownership

This opt-in implements Microsoft's [Private Link DNS integration at scale](https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/azure-best-practices/private-link-and-dns-integration-at-scale).
Spokes own vault/storage, private endpoints, scoped RBAC and audit diagnostics.
Platform Policy owns endpoint DNS zone groups. Existing zones, DNS forwarders
and resolver VNet links retain their owner, including manually created zones.
No legacy LZ code/output changes, zone creation or resource import are required.

The default is still `private_endpoint_dns_mode = "terraform"`. Default resource
addresses, names and DNS ownership are unchanged. The new policy-only endpoint
helper ignores only `private_dns_zone_group`; the original helper still enforces
Terraform-owned groups. Changing an existing endpoint's mode needs the handoff
below, not an unreviewed toggle-only apply.

## Platform First

Use the existing `platform-policy` workspace and explicitly load
[private-endpoint-dns.tfvars.example](../platform-lz/workspaces/platform-policy/private-endpoint-dns.tfvars.example)
after replacing every placeholder and obtaining network/security approval.
`private_endpoint_dns_policies = {}` is the inert default.

Each entry selects a governance MG key, existing Key Vault/Blob zone IDs, approval
reference, rollout exclusions and zone-RBAC ownership. Use disjoint scopes; do not
assign differing catalogs to overlapping ancestor/descendant MGs. Exclude
subscriptions/RGs still using another owner during adoption.

Verified Microsoft built-ins:
- Key Vault: `ac673a9a-f77d-4846-b2d8-a57f8e1c01d4`.
- Blob: `75973700-529f-4de2-b794-fb9b6781b6b0`.
Both receive `effect=DeployIfNotExists` and `privateDnsZoneId` centrally.

The existing remediation engine grants the policy system identity Network
Contributor at the selected MG. This is broader than zone-group actions: choose
the smallest approved workload scope and review aggregate permissions. Policy
exclusions do not narrow RBAC. The extension grants Private DNS Zone Contributor
at each exact zone; it does not adopt the zone itself. The deployer needs
role-assignment permission there. Alternatively set
`manage_zone_role_assignments=false` and have the existing DNS owner grant these
permissions using the published policy principal IDs. Policies are not operational
until those grants exist.

Review `private_endpoint_dns_registration` outputs, policy inheritance, scope
exclusions and cloud availability. These built-ins target automatic service
connections; manual approvals are rejected by the helper pending verified coverage.
The built-ins check group existence, not necessarily its correct zone, so live
acceptance still compares actual zone IDs.

Backfill is never automatic. An approved bounded `policy.remediation.tasks`
entry can use the generated assignment key from the output. Run existing-resource
tasks after zone permissions propagate, especially when the legacy owner grants
them outside this state. Only then set `private_endpoint_dns_backfill_approved=true`
for that reviewed backfill; the contract rejects DNS tasks without this approval.

## Spoke Inputs

Inside the existing internal-app root's `spoke` object, add:

```hcl
private_endpoint_dns_mode        = "policy"
policy_dns_registration_approved = true
```

Keep the other required network/IPAM/NVA, DNS-server, logging and application
inputs. Neither `private_dns_zone_ids` nor `platform_inputs.*_private_dns_zone_id`
is required in this mode. It offers no public fallback or new central DNS zones.
The approval flag is an operator decision, not proof of live readiness.
Standalone blueprint/Key Vault callers pass the same two arguments directly.
Select the updated module release before passing new arguments.

Key Vault still requires a private endpoint subnet. Initial data-plane key creation
is blocked in Policy mode: perform it separately after DNS, routing and RBAC
readiness. The vault and storage remain private and audited.

The reference spoke providers use `features.storage.data_plane_available=false`
with AzureRM 4.81 so foundation creation uses ARM rather than needing private
storage data-plane access before DNS exists. Preserve that setting in standalone
callers. Secret/key/blob operations belong after the readiness gate.

Both blueprint and vault examples include `variants/policy-owned-dns.tfvars`,
used with their baseline. They remain disabled/unapproved; mock tests substitute
approval only for test runs. Enable only after the platform rollout is verified.

Policy-mode attachment intent requests no automatic spoke-to-zone links. Central
attachment still owns both peerings. Use an approved inventory with no DNS links
when existing identity/hub forwarders supply resolution. Peering alone does not
inherit zone links or make routing transitive.

## Existing-State Handoff

1. Back up state; record existing endpoint/group IDs, names and approved zone IDs.
   Upgrade older wrappers in Terraform-owned mode first and review any automatic
   move to a keyed default endpoint before changing its DNS owner.
2. Deploy Policy and zone permissions, retaining rollout exclusions until ready.
3. Change the caller mode and move endpoint module state to the policy helper.
   Do not apply an intermediate destroy/create plan.
4. Require a saved plan with no endpoint/vault/storage replacement or record
   deletion. Remove the rollout exclusion only after the handoff.
5. Run live acceptance and a second normal plan after Policy convergence.
   Terraform must not remove/recreate the policy-owned group.

Example addresses for internal-app roots; adapt caller prefixes and keys:

```bash
terraform state mv 'module.blueprint[0].module.storage_endpoints["data"]' \
  'module.blueprint[0].module.storage_policy_endpoints["data"]'
terraform state mv 'module.blueprint[0].module.key_vault[0].module.private_endpoint["default"]' \
  'module.blueprint[0].module.key_vault[0].module.policy_private_endpoint["default"]'
```

Both helpers keep the leaf `azurerm_private_endpoint.private_endpoint` address.
The move changes ownership in state, not the Azure endpoint. Reversing ownership
also needs a reviewed state move and exact observed group configuration. Never
let Policy and Terraform enforce the child simultaneously. Preserve existing
VNet links until the replacement forwarding path passes live checks.

## Readiness Gate

DINE is asynchronous. A successful apply does not prove private connectivity.
After central attachment, use a network-connected runner with endpoint/NIC/group
read permissions. Obtain an independently approved flat JSON zone catalog from
the platform/DNS owner, with `key_vault` and/or `storage_blob` full zone IDs.
It is acceptance evidence, not a spoke Terraform input or state dependency.

```bash
terraform output -json spoke | python PATH/verify_spoke.py \
  --dns-zone-catalog approved-zones.json --timeout 1800
```

The read-only verifier discovers the group name (including `deployedByPolicy`),
checks approved zone IDs, endpoint approval, security and auditing, and requires
DNS to resolve exclusively to the actual endpoint NIC IPs plus TCP 443 access.
Policy mode does not require a direct spoke zone link. Application authentication
remains separate acceptance. Bounded retries fail on missing/wrong groups or
unavailable networking; they never open public access or silently pass.

Mock tests prove code behavior, not live Azure Policy/RBAC/DNS. Pilot registration,
the existing-state handoff and second-plan check before production rollout.
