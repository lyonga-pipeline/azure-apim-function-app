# Compeer Directory Services Pattern

This pattern deploys Azure infrastructure for hub-hosted directory services: resource group, NICs with stable keys, Windows VMs, optional data disks, optional diagnostics, optional RBAC, optional locks, and no-resource operational contracts.

It intentionally does not promote domain controllers, configure AD DS/DNS, create AD Sites and Services, or pass domain-admin secrets through Terraform. Optional machine domain join is available for approved cases and uses sensitive workspace variables.
