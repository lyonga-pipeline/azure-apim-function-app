# Policy-Owned DNS Private Endpoint

Creates only the endpoint/service connection. Azure Policy owns its DNS zone group.
There is no DNS-zone/group input. `policy_registration_approved=true` acknowledges
the separately deployed policies and their permissions; it is not live evidence.
Only automatic service connections are supported by the verified built-ins.

The resource deliberately uses `ignore_changes=[private_dns_zone_group]` and no
inline group so subsequent plans cannot reconcile a policy-created child to empty.
Every other endpoint property remains Terraform-managed. The original parent
module is unchanged and still enforces its configured groups.

Input types follow the parent helper for name, existing RG, location, subnet,
service connection, optional NIC/edge-zone/static IP, tags and timeouts.
Outputs expose endpoint IDs, subnet, NICs and observed service/DNS configuration.
Zone-group output is observational, not a readiness signal.

Do not change an existing helper source/module address without a reviewed state
handoff and a zero-replacement plan. Publish this submodule inside the private
endpoint registry package before registry consumers reference its subdirectory;
do not invent an HCP version for the old release that lacks it.

See [rollout guide](../../../../implementations/workload-lz/POLICY-DNS.md) in the catalog.
