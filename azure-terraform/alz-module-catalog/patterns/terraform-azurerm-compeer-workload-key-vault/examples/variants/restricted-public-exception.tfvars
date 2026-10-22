# NOT the spoke/production baseline. Only for an approved application/service
# that cannot use Private Link. Platform policy can still deny this configuration.
# Reference an actual authorized exception; this string is not approval itself.
private_endpoints = {}
network_access = {
  mode                       = "restricted_public"
  exception_reference        = "REPLACE_APPROVED_SECURITY_EXCEPTION_REFERENCE"
  ip_rules                   = ["203.0.113.10/32"] # Documentation-only IP; replace with real approved static PUBLIC egress.
  virtual_network_subnet_ids = []                  # Or existing subnets with Microsoft.KeyVault service endpoints enabled.
  trusted_services_bypass    = false
}
