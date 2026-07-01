# Workload Spoke Root

This root creates an application landing-zone network boundary.

It deploys the workload resource group, spoke VNet, subnets, optional NSG/route-table associations, optional spoke-to-hub peering, and optional Private DNS links. Application resources should be deployed from the app-owned consumer repo using the explicit outputs from this root and the shared platform workspaces.

Use one workspace per workload and environment. Workload spokes should consume platform outputs such as hub VNet ID, Private DNS zone names, Log Analytics workspace ID, and approved route targets through HCP variables or variable sets.

This root is a better OPA test target than `global-governance` because it creates taggable network resources and approved local module calls. For negative policy tests, temporarily use an unapproved region, remove required tag inputs, add a public IP, or introduce a PaaS resource with public network access in a branch.
