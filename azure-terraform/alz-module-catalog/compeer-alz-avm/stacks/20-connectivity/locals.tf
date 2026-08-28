locals {
  lock             = { kind = "CanNotDelete" }
  tags             = merge({ Environment = var.environment, ManagedBy = "Terraform", IaCSource = "AVM", LandingZone = "CentralUS" }, var.tags)
  required_subnets = ["GatewaySubnet", "MgmtSubnet", "UntrustSubnet", "TrustSubnet", "SharedServicesSubnet"]
}
