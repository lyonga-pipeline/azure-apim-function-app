# REFERENCE ONLY: five fictional approved external applications, not Compeer DNS.
# Three nonprod apps reuse external_nonprod; two prod apps reuse external_prod.
# No additional workspace, tunnel or connector fleet is needed per app.
#
# App key          Public hostname                 Private HTTPS origin
# lending_dev      lending-dev.example.com         lending-dev.origin.internal
# reports_test     reports-test.example.com        reports-test.origin.internal
# onboarding_uat   onboarding-uat.example.com      onboarding-uat.origin.internal
# customer_portal  portal.example.com              portal.origin.internal
# documents        documents.example.com           documents.origin.internal
#
# Each app has FOUR matching entries: approved hostname, tunnel ingress,
# Access application/policy and tunnel DNS. Shared WAF expressions include all
# five hosts. For a sixth app, extend those entries without renaming existing keys.
# Keep ingress rules ordered and review the full tunnel/ruleset update.
#
# This is a COMPLETE ALTERNATIVE to example.tfvars, not an overlay: Terraform
# replaces the cloudflare_edge object when another var-file supplies that key.
# Do not select both examples or blindly merge them into a deployed inventory.
# Select -var-file=five-apps.example.tfvars only in an approved isolated workspace
# after replacing placeholders and resolving existing resource ownership.
#
# Final-publication shape shown below. For staged migration, leave each new
# app's dns_records entry absent until its Access, WAF, TLS, private Azure path
# and both replicas are verified; preserve DNS for already-live applications.

cloudflare_edge = {
  enabled = true

  # Existing zone stays with its current owner; IDs below reference it only.
  zones   = {}
  records = {} # Mandatory empty in enterprise mode; DNS belongs to tunnels.

  approved_public_applications = {
    "lending-dev.example.com" = {
      classification = "external-apps", approval_reference = "REPLACE_WITH_LENDING_DEV_APPROVAL"
    }
    "reports-test.example.com" = {
      classification = "external-apps", approval_reference = "REPLACE_WITH_REPORTS_TEST_APPROVAL"
    }
    "onboarding-uat.example.com" = {
      classification = "external-apps", approval_reference = "REPLACE_WITH_ONBOARDING_UAT_APPROVAL"
    }
    "portal.example.com" = {
      classification = "external-apps", approval_reference = "REPLACE_WITH_PORTAL_PRODUCTION_APPROVAL"
    }
    "documents.example.com" = {
      classification = "external-apps", approval_reference = "REPLACE_WITH_DOCUMENTS_PRODUCTION_APPROVAL"
    }
  }

  # One owner per existing zone/phase: import entry points before adoption and
  # retain all other approved rules. Do not overwrite a shared tenant ruleset
  # with this fictional list. Confirm managed WAF entitlement and rule ID.
  rulesets = {
    external_custom = {
      zone_id = "REPLACE_WITH_EXISTING_ZONE_ID"
      name    = "Compeer external application custom protections"
      kind    = "zone"
      phase   = "http_request_firewall_custom"
      rules = [{
        ref         = "five_apps_standard_tls_ports"
        description = "Reject nonstandard ports for the five approved applications"
        expression  = "(http.host in {\"lending-dev.example.com\" \"reports-test.example.com\" \"onboarding-uat.example.com\" \"portal.example.com\" \"documents.example.com\"} and not cf.edge.server_port in {443})"
        action      = "block"
        enabled     = true
      }]
    }
    external_managed = {
      zone_id = "REPLACE_WITH_EXISTING_ZONE_ID"
      name    = "Compeer external application managed WAF"
      kind    = "zone"
      phase   = "http_request_firewall_managed"
      rules = [{
        ref               = "five_apps_managed_waf"
        description       = "Execute approved managed WAF for all five hostnames"
        expression        = "(http.host in {\"lending-dev.example.com\" \"reports-test.example.com\" \"onboarding-uat.example.com\" \"portal.example.com\" \"documents.example.com\"})"
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
      config_src        = "cloudflare"
      access_team_name  = "REPLACE-WITH-ZERO-TRUST-TEAM-SLUG"
      tunnel_secret_key = "external_nonprod"
      catch_all_service = "http_status:404"

      ingress_rules = [
        {
          hostname       = "lending-dev.example.com"
          service        = "https://lending-dev.origin.internal:443"
          origin_request = { origin_server_name = "lending-dev.origin.internal", no_tls_verify = false }
        },
        {
          hostname       = "reports-test.example.com"
          service        = "https://reports-test.origin.internal:443"
          origin_request = { origin_server_name = "reports-test.origin.internal", no_tls_verify = false }
        },
        {
          hostname       = "onboarding-uat.example.com"
          service        = "https://onboarding-uat.origin.internal:443"
          origin_request = { origin_server_name = "onboarding-uat.origin.internal", no_tls_verify = false }
        },
      ]
      # Stable application keys, not Azure resource names. The helper derives
      # IDs/JWT audiences; policies reference these keys, not pasted app IDs.
      access_applications = {
        lending_dev = {
          name                       = "Lending development", domain = "lending-dev.example.com"
          type                       = "self_hosted", session_duration = "8h"
          allowed_idps               = ["REPLACE_WITH_CLOUDFLARE_IDP_ID"]
          http_only_cookie_attribute = true
        }
        reports_test = {
          name                       = "Reporting test", domain = "reports-test.example.com"
          type                       = "self_hosted", session_duration = "8h"
          allowed_idps               = ["REPLACE_WITH_CLOUDFLARE_IDP_ID"]
          http_only_cookie_attribute = true
        }
        onboarding_uat = {
          name                       = "Onboarding UAT", domain = "onboarding-uat.example.com"
          type                       = "self_hosted", session_duration = "8h"
          allowed_idps               = ["REPLACE_WITH_CLOUDFLARE_IDP_ID"]
          http_only_cookie_attribute = true
        }
      }
      # Group/posture checks must already exist. IAM approves membership, MFA,
      # device requirements and session durations; this example does not create them.
      access_policies = {
        lending_dev_users = {
          name     = "Lending dev approved users", application_key = "lending_dev"
          decision = "allow", precedence = 1
          include  = [{ group = ["REPLACE_WITH_LENDING_DEV_ACCESS_GROUP_ID"] }]
          require  = [{ device_posture = ["REPLACE_WITH_POSTURE_CHECK_ID"] }]
        }
        reports_test_users = {
          name     = "Reports test approved users", application_key = "reports_test"
          decision = "allow", precedence = 1
          include  = [{ group = ["REPLACE_WITH_REPORTS_TEST_ACCESS_GROUP_ID"] }]
          require  = [{ device_posture = ["REPLACE_WITH_POSTURE_CHECK_ID"] }]
        }
        onboarding_uat_users = {
          name     = "Onboarding UAT approved users", application_key = "onboarding_uat"
          decision = "allow", precedence = 1
          include  = [{ group = ["REPLACE_WITH_ONBOARDING_UAT_ACCESS_GROUP_ID"] }]
          require  = [{ device_posture = ["REPLACE_WITH_POSTURE_CHECK_ID"] }]
        }
      }
      # Publish each new app only after acceptance. CNAME targets are generated.
      dns_records = {
        lending_dev = {
          zone_id = "REPLACE_WITH_EXISTING_ZONE_ID", name = "lending-dev.example.com"
          type    = "CNAME", proxied = true, ttl = 1, allow_overwrite = false
        }
        reports_test = {
          zone_id = "REPLACE_WITH_EXISTING_ZONE_ID", name = "reports-test.example.com"
          type    = "CNAME", proxied = true, ttl = 1, allow_overwrite = false
        }
        onboarding_uat = {
          zone_id = "REPLACE_WITH_EXISTING_ZONE_ID", name = "onboarding-uat.example.com"
          type    = "CNAME", proxied = true, ttl = 1, allow_overwrite = false
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
      ingress_rules = [
        {
          hostname       = "portal.example.com"
          service        = "https://portal.origin.internal:443"
          origin_request = { origin_server_name = "portal.origin.internal", no_tls_verify = false }
        },
        {
          hostname       = "documents.example.com"
          service        = "https://documents.origin.internal:443"
          origin_request = { origin_server_name = "documents.origin.internal", no_tls_verify = false }
        },
      ]
      access_applications = {
        customer_portal = {
          name                       = "Production customer portal", domain = "portal.example.com"
          type                       = "self_hosted", session_duration = "4h"
          allowed_idps               = ["REPLACE_WITH_CLOUDFLARE_IDP_ID"]
          http_only_cookie_attribute = true
        }
        documents = {
          name                       = "Production documents", domain = "documents.example.com"
          type                       = "self_hosted", session_duration = "4h"
          allowed_idps               = ["REPLACE_WITH_CLOUDFLARE_IDP_ID"]
          http_only_cookie_attribute = true
        }
      }
      # This illustration uses approved IdP users for BOTH apps. A real public
      # customer-auth app needs its own reviewed alternative-authentication design;
      # do not remove Access or add bypass merely because its name says customer.
      access_policies = {
        portal_users = {
          name     = "Portal approved users", application_key = "customer_portal"
          decision = "allow", precedence = 1
          include  = [{ group = ["REPLACE_WITH_PORTAL_ACCESS_GROUP_ID"] }]
          require  = [{ device_posture = ["REPLACE_WITH_POSTURE_CHECK_ID"] }]
        }
        document_users = {
          name     = "Documents approved users", application_key = "documents"
          decision = "allow", precedence = 1
          include  = [{ group = ["REPLACE_WITH_DOCUMENTS_ACCESS_GROUP_ID"] }]
          require  = [{ device_posture = ["REPLACE_WITH_POSTURE_CHECK_ID"] }]
        }
      }
      dns_records = {
        customer_portal = {
          zone_id = "REPLACE_WITH_EXISTING_ZONE_ID", name = "portal.example.com"
          type    = "CNAME", proxied = true, ttl = 1, allow_overwrite = false
        }
        documents = {
          zone_id = "REPLACE_WITH_EXISTING_ZONE_ID", name = "documents.example.com"
          type    = "CNAME", proxied = true, ttl = 1, allow_overwrite = false
        }
      }
    }
  }
}

# SHAPE ONLY: remove this assignment from deployed tfvars and supply real
# independent 32-byte base64 creation secrets through a sensitive HCP input.
# NEVER commit real secrets. Existing tunnel secrets are reused for onboarding;
# adding an app does NOT require rotating tokens or reinstalling connectors.
cloudflare_tunnel_secrets = {
  external_nonprod = "REPLACE_VIA_SENSITIVE_HCP_VARIABLE_NOT_GIT"
  external_prod    = "REPLACE_VIA_DIFFERENT_SENSITIVE_HCP_VARIABLE_NOT_GIT"
}
