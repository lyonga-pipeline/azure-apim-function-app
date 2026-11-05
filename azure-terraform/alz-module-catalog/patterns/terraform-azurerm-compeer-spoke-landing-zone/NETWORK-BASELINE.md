# Network Defaults And Application Ownership

The blueprint implements the supplied design, not an application firewall policy.
It generates no custom NSG allow or deny rules. Every subnet retains its NSG,
route table and associations. The hub firewall owns the documented default-deny
policy; project teams own subnet-level traffic rules through tfvars.
Azure's built-in NSG rules are not removed and include VNet/load-balancer/outbound
allows. An empty rule map is not a subnet default-deny policy, and the hub firewall
does not inspect traffic that stays within the same VNet.

## Design Traceability

| Configuration | Decision and source |
| --- | --- |
| Priority-4096 subnet deny rules | Removed from generated defaults. Architecture and Design v13 sections 8.5/12.3 require default-deny security but do not mandate these two rules in every spoke NSG. Teams may explicitly retain them in tfvars where approved. |
| NVA default route and hub/approved remote-prefix UDRs | Retained to implement v13 sections 8.2/8.5/12.6: spoke Internet, on-premises and inter-spoke traffic must be inspected. The detailed network deployment document also requires UDRs to override peering routes and updates when adding spokes. |
| BGP propagation disabled, no direct gateway/Internet bypass | Retained to preserve that inspection model. NVA readiness, effective routes and return-path symmetry still require network-team validation. |
| Automatic DNS, load-balancer probe, private HTTPS and Internet HTTPS allows | Removed. The design does not prescribe these rules for every workload. Approved application traffic belongs in project tfvars. |
| Hardcoded Sunstream NSG rules and remote-prefix route | Removed from this spoke pattern. The priority-100 Sunstream requirement in Azure Resource Deployment in New Landing Zone v2 is under Hub Subnet NSGs; it is not an instruction to copy all hub rules into workload spokes. Hub controls are unchanged. Add any approved workload-specific partner controls explicitly. |

This cleanup is scoped to generated spoke networking defaults. It does not remove
the private-resource, identity, encryption, logging or other separately governed
controls.

## Project Configuration

Put explicit rules in `spoke.subnets.<key>.rules` for implementation roots, or
`subnets.<key>.rules` for a direct blueprint call. The
[baseline tfvars](examples/baseline.tfvars) demonstrate approved-source inbound
HTTPS, custom DNS over UDP/TCP 53, and private-endpoint HTTPS in both directions.
All example IPs are synthetic and must be replaced.

- Rules use unique priorities per direction in Azure's supported 100-4096 range.
  No NSG rule names are reserved. Teams can keep former `baseline-deny-*` names
  explicitly, including priority 4096, without renaming their Azure rules.
- For custom DNS, allow only the approved resolver IPs on the required subnets.
  Setting `platform.dns_server_ips` configures the VNet, not NSG authorization.
- Azure-provided DNS needs no explicit `Allow -> AzurePlatformDNS` rule.
  The special tag is for explicitly blocking platform DNS; an Allow is rejected.
- Private endpoints may be created without custom NSG rules. Actual access depends
  on Azure's effective NSG rules, DNS, routing, service firewall and RBAC. Do not
  infer denial or connectivity merely from an empty rule map.
- Add a load-balancer probe rule only for an actual load-balanced workload, scoped
  to its probe protocol/port. Internet egress also requires an explicit reviewed
  rule plus the independently approved Palo Alto policy.
- `private_endpoint_client_cidrs` remains accepted for source compatibility but
  no longer creates rules. Move those source CIDRs into explicit endpoint rules.
- Add exact approved remote CIDRs to `inspection_address_prefixes`; hub prefixes
  and the NVA default route remain automatic. For additional permitted NVA or
  blackhole routes, use `subnets.<key>.routes`. Do not duplicate generated prefixes.

The [explicit-subnet-deny variant](examples/variants/explicit-subnet-deny.tfvars)
demonstrates a team-owned deny-by-default profile with explicit DNS/private HTTPS
allows. It is optional and is not injected into other profiles. DNS registration
and successful resource creation do not prove traffic policy or connectivity.

## Existing Spoke Upgrade

1. Inventory every former `baseline-deny-*`, `baseline-dns-*`, `baseline-health-probe`,
   `baseline-private-https`, `baseline-egress-https` and Sunstream rule in the
   saved plan/current NSG. Confirm which flows the workload actually needs.
2. Move required rules into project tfvars before upgrading. Existing NSG rule
   names and priority-4096 denies can be retained explicitly. Confirm removal of
   denies with the security owner; this can widen allowed subnet traffic.
   Preserve approved partner controls and remote routing requirements as needed.
3. Publish/select a new blueprint release and update the caller pin explicitly.
   This changes traffic policy and must not be silently promoted as a no-impact
   upgrade. The catalog base NSG helper now emits an explicit `security_rule=[]`
   when both rule inputs are empty. AzureRM otherwise may retain the last old
   inline rules when a dynamic block is omitted. Publish a new base NSG registry
   release containing this fix and select that approved version in the Compeer
   blueprint before removing all rules from an existing NSG. No input/output or
   resource-address change is needed; do not overwrite a published tag.
   The Compeer copy keeps its existing registry pin until that release is available.
   The RG module is unrelated to this networking change.
4. Review the refreshed plan in the existing workspace: expect inline NSG-rule
   updates (including removed denies) and removal of the automatic partner UDR,
   not VNet/subnet replacement. Verify an explicit empty collection is planned
   when the last custom rule is removed; do not assume that an empty input cleared it.
   Do not delete resources or discard state after a partial apply.
5. Apply in a change window and verify DNS, endpoint HTTPS, required probes,
   effective routes and firewall symmetry from the actual application networks.

Mock tests verify generated inputs and rejection of invalid platform-DNS allows;
they do not prove Azure acceptance, routing or connectivity.
