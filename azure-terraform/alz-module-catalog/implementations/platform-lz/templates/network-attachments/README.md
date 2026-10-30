# Independent Attachment Root Template

Copy this template **once per approved environment/platform lifecycle and hub boundary** into its own `workspaces/platform-network-peering-<boundary>` directory. Commit that root's real environment, inventory and release pin there; create an independent HCP state/working-directory/trigger/OIDC boundary. Do not deploy several environments from this template directory by switching runtime tfvars.

The four existing np1/np2/np3/prod roots are examples, not an environment enum, minimum workspace count or application deployment matrix. Create only roots actually needed. An approved label such as `shared`, `dev`, `perf`, `dr`, or `integration` is accepted. The consumer enforces that every declared producer belongs to that root's actual environment; it does not silently filter mismatched entries or relabel platform resources to fit.

Use `attachment_kind="platform"` for a hub-to-platform VNet attachment and `"workload"` for a hub-to-application VNet. Generic producers publish `network_attachment_contract` v3; the existing workload `attachment_contract` v2 remains supported without changing its producers. No dummy application code, workload domain or naming context is needed for v3. Platform and workload VNets keep their original owners; this root creates only both peering directions and approved links.

Examples:
- [Shared platform VNet](../../../../patterns/terraform-azapi-compeer-network-attachments/examples/shared-platform.tfvars.example).
- [Applications with one, two and three environments](../../../../patterns/terraform-azapi-compeer-network-attachments/examples/application-environments/README.md).
- [Output-only producer adapter](../../../../patterns/terraform-azapi-compeer-network-attachments/producer/README.md).
- [Gate, permission and migration controls](../../network-attachments/README.md).

All examples are disabled and use documentation placeholders. Copy first, replace/review values, publish/pin the package and configure the common hub gate and exact OIDC/RBAC grants before enabling. Existing split-owned identity peerings must undergo a reviewed handoff; publishing a new output does not transfer ownership. If a platform VNet is actually classified `prod`, use a prod-classified approved root rather than claiming its environment is shared. The template does not authorize uninspected spoke-to-spoke mesh connectivity.
