# REFERENCE ONLY: not auto-loaded. Merge reviewed values into terraform.tfvars,
# or explicitly use -var-file=example.tfvars in a sandbox after replacing inputs.
# Never apply placeholders. This is desired FINAL publication configuration;
# first provision security with BOTH tunnel dns_records maps empty, then publish
# only after WAF, replicas, origin TLS and authorization acceptance.
#
# Diagram: Central US hub, one shared nonprod tunnel and one prod tunnel.
# np01/np02 use external_nonprod's runtime token; prod01/prod02 use external_prod's.
# Each pair spans two AZs. dev/test/uat/sandbox (or approved legacy NP labels)
# share the nonprod fleet; add hostnames/apps, not new tunnels per app.
# Terraform here does not change Azure networking or origin public access.
# Origin owners must disable/restrict public access and provide private DNS,
# HTTPS endpoints, Palo Alto permits and symmetric routes before publication.
#
# CLOUDFLARE_API_TOKEN: sensitive ENV input, never a tfvars/API-key literal.
# Obtain account/zone IDs, IdP/Access-group/posture IDs, team slug and licensed
# managed-WAF ID from their Cloudflare/IAM owners, not from Azure subscription IDs.

cloudflare_edge = {
  enabled = true

  # This example shows explicit zone ownership. IMPORT the existing zone into
  # module.cloudflare_edge.cloudflare_zone.zone["external"] before adoption,
  # reviewing its complete settings. Do not recreate an existing domain.
  # If another state owns it, set zones={} and replace EVERY zone_key below
  # with zone_id="ACTUAL_EXISTING_ZONE_ID" instead. Never use both on one entry.
  zones = {
    external = {
      zone       = "example.com" # Replace with the approved Compeer domain.
      account_id = "REPLACE_WITH_CLOUDFLARE_ACCOUNT_ID"
      type       = "full" # Confirm DNS delegation/zone type with its owner.
      paused     = false
    }
  }

  # REQUIRED EMPTY in enterprise mode. Application CNAME records are populated
  # under tunnels[*].dns_records below. Generic records bypass publication guards.
  records = {}

  approved_public_applications = {
    "portal-uat.example.com" = {
      classification     = "external-apps"
      approval_reference = "REPLACE_WITH_APPROVED_NONPROD_CHANGE"
    }
    "portal.example.com" = {
      classification     = "external-apps"
      approval_reference = "REPLACE_WITH_APPROVED_PRODUCTION_CHANGE"
    }
  }

  # One owner per zone/phase. IMPORT existing entry points and preserve ALL
  # existing approved rules; these illustrative lists are not a tenant inventory.
  # WAF is NOT automatically bound to an Access app: host expressions do that.
  rulesets = {
    external_custom = {
      zone_key    = "external"
      name        = "Compeer external application custom protections"
      description = "Approved host-scoped rules for nonprod and production"
      kind        = "zone"
      phase       = "http_request_firewall_custom"
      rules = [{
        ref         = "portal_standard_tls_ports"
        description = "Reject nonstandard ports for the approved portals"
        expression  = "(http.host in {\"portal-uat.example.com\" \"portal.example.com\"} and not cf.edge.server_port in {443})"
        action      = "block"
        enabled     = true
      }]
    }
    external_managed = {
      zone_key = "external"
      name     = "Compeer external application managed WAF"
      kind     = "zone"
      phase    = "http_request_firewall_managed"
      rules = [{
        ref               = "portal_managed_waf"
        description       = "Run licensed reviewed managed protections on both portals"
        expression        = "(http.host in {\"portal-uat.example.com\" \"portal.example.com\"})"
        action            = "execute"
        action_parameters = { id = "REPLACE_WITH_32_CHARACTER_MANAGED_WAF_ID" }
        enabled           = true
      }]
    }
  }

  tunnels = {
    external_nonprod = {
      account_id        = "REPLACE_WITH_CLOUDFLARE_ACCOUNT_ID"
      name              = "compeer-cus-external-nonprod"
      config_src        = "cloudflare" # Remote ingress owned by Terraform.
      access_team_name  = "REPLACE-WITH-ZERO-TRUST-TEAM-SLUG"
      tunnel_secret_key = "external_nonprod"
      catch_all_service = "http_status:404"
      ingress_rules = [{
        hostname = "portal-uat.example.com"
        service  = "https://portal-uat.origin.internal:443"
        origin_request = {
          origin_server_name = "portal-uat.origin.internal"
          http_host_header   = "portal-uat.origin.internal"
          no_tls_verify      = false
          connect_timeout    = "30s"
          tls_timeout        = "10s"
        }
      }]
      access_applications = {
        portal_uat = {
          name                       = "Compeer portal UAT"
          domain                     = "portal-uat.example.com"
          type                       = "self_hosted"
          allowed_idps               = ["REPLACE_WITH_CLOUDFLARE_IDP_ID"]
          auto_redirect_to_identity  = true
          session_duration           = "8h" # IAM must approve durations.
          http_only_cookie_attribute = true
        }
      }
      access_policies = {
        portal_uat_users = {
          name            = "Approved UAT users on compliant devices"
          application_key = "portal_uat"
          decision        = "allow"
          precedence      = 1
          include         = [{ group = ["REPLACE_WITH_NONPROD_ACCESS_GROUP_ID"] }]
          require         = [{ device_posture = ["REPLACE_WITH_POSTURE_CHECK_ID"] }]
          exclude         = [{ group = ["REPLACE_WITH_SUSPENDED_ACCESS_GROUP_ID"] }]
        }
      }
      # Final publication only. Set {} during initial configuration/acceptance.
      dns_records = {
        portal_uat = {
          zone_key        = "external"
          name            = "portal-uat.example.com"
          type            = "CNAME"
          proxied         = true
          ttl             = 1
          allow_overwrite = false
          comment         = "Approved nonprod portal through the shared nonprod tunnel"
          # content omitted: generated tunnel CNAME, not a pasted tunnel ID.
        }
      }
    }
    external_prod = {
      account_id        = "REPLACE_WITH_CLOUDFLARE_ACCOUNT_ID"
      name              = "compeer-cus-external-prod"
      config_src        = "cloudflare"
      access_team_name  = "REPLACE-WITH-ZERO-TRUST-TEAM-SLUG"
      tunnel_secret_key = "external_prod"
      catch_all_service = "http_status:404"
      ingress_rules = [{
        hostname = "portal.example.com"
        service  = "https://portal.origin.internal:443"
        origin_request = {
          origin_server_name = "portal.origin.internal"
          http_host_header   = "portal.origin.internal"
          no_tls_verify      = false
          connect_timeout    = "30s"
          tls_timeout        = "10s"
        }
      }]
      access_applications = {
        portal = {
          name                       = "Compeer production portal"
          domain                     = "portal.example.com"
          type                       = "self_hosted"
          allowed_idps               = ["REPLACE_WITH_CLOUDFLARE_IDP_ID"]
          auto_redirect_to_identity  = true
          session_duration           = "4h"
          http_only_cookie_attribute = true
        }
      }
      access_policies = {
        portal_users = {
          name            = "Approved production users on compliant devices"
          application_key = "portal"
          decision        = "allow"
          precedence      = 1
          include         = [{ group = ["REPLACE_WITH_PRODUCTION_ACCESS_GROUP_ID"] }]
          require         = [{ device_posture = ["REPLACE_WITH_POSTURE_CHECK_ID"] }]
          exclude         = [{ group = ["REPLACE_WITH_SUSPENDED_ACCESS_GROUP_ID"] }]
        }
      }
      dns_records = {
        portal = {
          zone_key        = "external"
          name            = "portal.example.com"
          type            = "CNAME"
          proxied         = true
          ttl             = 1
          allow_overwrite = false
          comment         = "Approved production portal through production-only replicas"
        }
      }
    }
  }
}

# SHAPE ONLY. Do not replace these with real credentials in a committed file.
# Supply the actual map as a sensitive Terraform-category HCP workspace variable
# cloudflare_tunnel_secrets, omitting this assignment from deployed tfvars (a
# committed tfvars assignment can take precedence over workspace input).
# Generate independent random 32-byte values, canonical-base64 encoded, through
# an approved secret process. These are CREATION secrets, not runtime tokens.
# The release job delivers each tunnel's runtime token to its own Key Vault
# secret: cloudflare-nonprod-token / cloudflare-prod-token. See connector guide.
cloudflare_tunnel_secrets = {
  external_nonprod = "REPLACE_VIA_SENSITIVE_HCP_VARIABLE_NOT_GIT"
  external_prod    = "REPLACE_VIA_DIFFERENT_SENSITIVE_HCP_VARIABLE_NOT_GIT"
}
