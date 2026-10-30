# =============================================================================
# PHASE 2 EXISTING CAPABILITY - NET-34
# Retain existing Cloudflare tunnel/Access/DNS owner; do not create a parallel Phase 2 edge state.
# Engineering map: implementations/phase2/ENGINEERING-HANDOFF.md
# =============================================================================
module "cloudflare_edge" {
  source = "../../../../patterns/terraform-cloudflare-compeer-edge-baseline"

  providers = {
    cloudflare = cloudflare
  }

  enabled  = try(var.cloudflare_edge.enabled, false)
  zones    = try(var.cloudflare_edge.zones, {})
  records  = try(var.cloudflare_edge.records, {})
  rulesets = try(var.cloudflare_edge.rulesets, {})
  tunnels  = try(var.cloudflare_edge.tunnels, {})

  tunnel_secrets = var.cloudflare_tunnel_secrets
}
