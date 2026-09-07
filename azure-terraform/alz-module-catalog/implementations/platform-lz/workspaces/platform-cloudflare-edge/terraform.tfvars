# Deployable tfvars - Cloudflare edge workspace (no Azure).
#
# Auth is NOT set here: the Cloudflare API token comes from the shared HCP
# variable set as the env-category variable CLOUDFLARE_API_TOKEN.
#

cloudflare_edge = {
  enabled  = false
  zones    = {}
  records  = {}
  rulesets = {}
  tunnels  = {}
}

cloudflare_tunnel_secrets = {}
