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
  # PHASE 2: exact approved public hostnames only. Internal/regulated apps
  # are rejected. Access is required unless alternative authentication is approved.
  approved_public_applications = {
    # "pilot.example.com" = { classification = "external-apps", approval_reference = "REPLACE_WITH_APPROVED_CHANGE" }
  }
}

cloudflare_tunnel_secrets = {}
