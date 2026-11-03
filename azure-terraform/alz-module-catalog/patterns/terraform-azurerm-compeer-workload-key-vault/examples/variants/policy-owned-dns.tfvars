# Use with baseline.tfvars. The approved platform policy owns zone groups and records.
# All other private security controls and central auditing remain enabled.
private_endpoint_dns_mode        = "policy"
policy_dns_registration_approved = false # Explicitly approve only after platform readiness.
private_dns_zone_id              = null
private_endpoints = {
  default = {
    subnet_id = "/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/network/providers/Microsoft.Network/virtualNetworks/orders-prod/subnets/private-endpoints"
  }
}
keys = {}
