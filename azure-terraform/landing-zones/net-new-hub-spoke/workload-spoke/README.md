# Workload Spoke Root

This root creates an application landing-zone network boundary.

It deploys the workload resource group, spoke VNet, subnets, optional NSG/route-table associations, optional spoke-to-hub peering, and optional Private DNS links. Application resources should be deployed from the app-owned consumer repo using the explicit outputs from this root and the shared platform workspaces.

