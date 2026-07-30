subscription_id = "ce792f64-9e63-483b-8136-a2538b764f3d"
tenant_id       = "79dd759b-3fbe-4ab1-9439-ff87b14ba8f2"

# Safety default: keep false until the catalog is reviewed and approved.
vending_enabled = false

# Azure portal: Subscriptions > Add > Create a subscription > Basics.
# The portal displays:
# Billing account  = Charles Lyonga (...truncated...)
# Billing profile  = Charles Lyonga (BARQ-ROVI-BG7-PGB)
# Invoice section  = Charles Lyonga (MRM-PUUU-PJA-PGB)
# Plan             = Microsoft Azure Plan
billing_account_name = "42f53d0e-734b-5ce6-0e37-1d640f0e75a1:d72eaae8-d2de-461c-ba3b-5bf77d323692_2019-05-31"
billing_profile_name = "BARQ-ROVI-BG7-PGB"
invoice_section_name = "MRM-PUUU-PJA-PGB"

# Leave blank when using the MCA billing_account/profile/invoice_section fields.
# Set this only when a client uses an EA billing scope or wants to pass the full
# billing scope directly.
default_billing_scope_id = ""

default_tags = {
  created_by          = "terraform"
  source_repo         = "ado://Compeer/azure-cloud"
  tf_workspace        = "subscription-vending"
  bt_owner            = "Cloud Enablement"
  recovery            = "standard"
  cost_center         = "cloud-platform"
  data_classification = "internal"
  compliance_boundary = "finserv"
}

management_groups = {
  "compeer-enterprise-mg" = {
    display_name = "Compeer Enterprise"
  }

  "platform-mg" = {
    display_name = "Platform"
    parent_key   = "compeer-enterprise-mg"
  }
  "security-mg" = {
    display_name = "Security"
    parent_key   = "platform-mg"
  }
  "identity-mg" = {
    display_name = "Identity"
    parent_key   = "platform-mg"
  }
  "management-mg" = {
    display_name = "Management"
    parent_key   = "platform-mg"
  }
  "connectivity-mg" = {
    display_name = "Connectivity"
    parent_key   = "platform-mg"
  }

  "workloads-mg" = {
    display_name = "Workloads"
    parent_key   = "compeer-enterprise-mg"
  }
  "internal-apps-mg" = {
    display_name = "Internal Apps"
    parent_key   = "workloads-mg"
  }
  "internal-apps-dev-mg" = {
    display_name = "Internal Apps - Dev"
    parent_key   = "internal-apps-mg"
  }
  "internal-apps-test-mg" = {
    display_name = "Internal Apps - Test"
    parent_key   = "internal-apps-mg"
  }
  "internal-apps-prod-mg" = {
    display_name = "Internal Apps - Prod"
    parent_key   = "internal-apps-mg"
  }

  "external-apps-mg" = {
    display_name = "External Apps"
    parent_key   = "workloads-mg"
  }
  "external-apps-dev-mg" = {
    display_name = "External Apps - Dev"
    parent_key   = "external-apps-mg"
  }
  "external-apps-test-mg" = {
    display_name = "External Apps - Test"
    parent_key   = "external-apps-mg"
  }
  "external-apps-prod-mg" = {
    display_name = "External Apps - Prod"
    parent_key   = "external-apps-mg"
  }

  # Go-live regulated-apps tree. Keep stricter controls scoped here as regulated workloads mature.
  "regulated-apps-mg" = {
    display_name = "Regulated Apps"
    parent_key   = "workloads-mg"
    enabled      = true
  }
  "regulated-apps-dev-mg" = {
    display_name = "Regulated Apps - Dev"
    parent_key   = "regulated-apps-mg"
    enabled      = true
  }
  "regulated-apps-test-mg" = {
    display_name = "Regulated Apps - Test"
    parent_key   = "regulated-apps-mg"
    enabled      = true
  }
  "regulated-apps-prod-mg" = {
    display_name = "Regulated Apps - Prod"
    parent_key   = "regulated-apps-mg"
    enabled      = true
  }

  # Go-live shared-services tree. Use this for enterprise shared service subscriptions.
  "shared-services-mg" = {
    display_name = "Shared Services"
    parent_key   = "workloads-mg"
    enabled      = true
  }
  "shared-services-dev-mg" = {
    display_name = "Shared Services - Dev"
    parent_key   = "shared-services-mg"
    enabled      = true
  }
  "shared-services-test-mg" = {
    display_name = "Shared Services - Test"
    parent_key   = "shared-services-mg"
    enabled      = true
  }
  "shared-services-prod-mg" = {
    display_name = "Shared Services - Prod"
    parent_key   = "shared-services-mg"
    enabled      = true
  }

  "sandbox-mg" = {
    display_name = "Sandbox"
    parent_key   = "compeer-enterprise-mg"
  }
  "decommissioned-mg" = {
    display_name = "Decommissioned"
    parent_key   = "compeer-enterprise-mg"
  }
}

subscriptions = {
  "platform-security-sub" = {
    management_group_key = "security-mg"
    workload             = "Production"
    tags = {
      application      = "platform-security"
      env              = "platform"
      environment_type = "platform"
      platform_domain  = "security"
    }
  }
  "platform-identity-sub" = {
    management_group_key = "identity-mg"
    workload             = "Production"
    tags = {
      application      = "platform-identity"
      env              = "platform"
      environment_type = "platform"
      platform_domain  = "identity"
    }
  }
  "platform-management-sub" = {
    management_group_key = "management-mg"
    workload             = "Production"
    tags = {
      application      = "platform-management"
      env              = "platform"
      environment_type = "platform"
      platform_domain  = "management"
    }
  }
  "platform-connectivity-sub" = {
    management_group_key = "connectivity-mg"
    workload             = "Production"
    tags = {
      application      = "platform-connectivity"
      env              = "platform"
      environment_type = "platform"
      platform_domain  = "connectivity"
    }
  }

  "internal-apps-dev-workload1-sub" = {
    management_group_key = "internal-apps-dev-mg"
    workload             = "DevTest"
    tags = {
      application      = "internal-apps-workload1"
      env              = "dev"
      environment_type = "nonprod"
      workload_domain  = "internal-apps"
    }
  }
  "internal-apps-dev-workload2-sub" = {
    management_group_key = "internal-apps-dev-mg"
    workload             = "DevTest"
    tags = {
      application      = "internal-apps-workload2"
      env              = "dev"
      environment_type = "nonprod"
      workload_domain  = "internal-apps"
    }
  }
  "internal-apps-dev-workload3-sub" = {
    management_group_key = "internal-apps-dev-mg"
    workload             = "DevTest"
    tags = {
      application      = "internal-apps-workload3"
      env              = "dev"
      environment_type = "nonprod"
      workload_domain  = "internal-apps"
    }
  }
  "internal-apps-test-workload1-sub" = {
    management_group_key = "internal-apps-test-mg"
    workload             = "DevTest"
    tags = {
      application      = "internal-apps-workload1"
      env              = "test"
      environment_type = "nonprod"
      workload_domain  = "internal-apps"
    }
  }
  "internal-apps-test-workload2-sub" = {
    management_group_key = "internal-apps-test-mg"
    workload             = "DevTest"
    tags = {
      application      = "internal-apps-workload2"
      env              = "test"
      environment_type = "nonprod"
      workload_domain  = "internal-apps"
    }
  }
  "internal-apps-test-workload3-sub" = {
    management_group_key = "internal-apps-test-mg"
    workload             = "DevTest"
    tags = {
      application      = "internal-apps-workload3"
      env              = "test"
      environment_type = "nonprod"
      workload_domain  = "internal-apps"
    }
  }
  "internal-apps-prod-workload1-sub" = {
    management_group_key = "internal-apps-prod-mg"
    workload             = "Production"
    tags = {
      application      = "internal-apps-workload1"
      env              = "prod"
      environment_type = "prod"
      workload_domain  = "internal-apps"
    }
  }
  "internal-apps-prod-workload2-sub" = {
    management_group_key = "internal-apps-prod-mg"
    workload             = "Production"
    tags = {
      application      = "internal-apps-workload2"
      env              = "prod"
      environment_type = "prod"
      workload_domain  = "internal-apps"
    }
  }
  "internal-apps-prod-workload3-sub" = {
    management_group_key = "internal-apps-prod-mg"
    workload             = "Production"
    tags = {
      application      = "internal-apps-workload3"
      env              = "prod"
      environment_type = "prod"
      workload_domain  = "internal-apps"
    }
  }

  "external-apps-dev-workload4-sub" = {
    management_group_key = "external-apps-dev-mg"
    workload             = "DevTest"
    tags = {
      application      = "external-apps-workload4"
      env              = "dev"
      environment_type = "nonprod"
      workload_domain  = "external-apps"
    }
  }
  "external-apps-dev-workload5-sub" = {
    management_group_key = "external-apps-dev-mg"
    workload             = "DevTest"
    tags = {
      application      = "external-apps-workload5"
      env              = "dev"
      environment_type = "nonprod"
      workload_domain  = "external-apps"
    }
  }
  "external-apps-dev-workload6-sub" = {
    management_group_key = "external-apps-dev-mg"
    workload             = "DevTest"
    tags = {
      application      = "external-apps-workload6"
      env              = "dev"
      environment_type = "nonprod"
      workload_domain  = "external-apps"
    }
  }
  "external-apps-test-workload4-sub" = {
    management_group_key = "external-apps-test-mg"
    workload             = "DevTest"
    tags = {
      application      = "external-apps-workload4"
      env              = "test"
      environment_type = "nonprod"
      workload_domain  = "external-apps"
    }
  }
  "external-apps-test-workload5-sub" = {
    management_group_key = "external-apps-test-mg"
    workload             = "DevTest"
    tags = {
      application      = "external-apps-workload5"
      env              = "test"
      environment_type = "nonprod"
      workload_domain  = "external-apps"
    }
  }
  "external-apps-test-workload6-sub" = {
    management_group_key = "external-apps-test-mg"
    workload             = "DevTest"
    tags = {
      application      = "external-apps-workload6"
      env              = "test"
      environment_type = "nonprod"
      workload_domain  = "external-apps"
    }
  }
  "external-apps-prod-workload4-sub" = {
    management_group_key = "external-apps-prod-mg"
    workload             = "Production"
    tags = {
      application      = "external-apps-workload4"
      env              = "prod"
      environment_type = "prod"
      workload_domain  = "external-apps"
    }
  }
  "external-apps-prod-workload5-sub" = {
    management_group_key = "external-apps-prod-mg"
    workload             = "Production"
    tags = {
      application      = "external-apps-workload5"
      env              = "prod"
      environment_type = "prod"
      workload_domain  = "external-apps"
    }
  }
  "external-apps-prod-workload6-sub" = {
    management_group_key = "external-apps-prod-mg"
    workload             = "Production"
    tags = {
      application      = "external-apps-workload6"
      env              = "prod"
      environment_type = "prod"
      workload_domain  = "external-apps"
    }
  }

  "regulated-apps-dev-workload7-sub" = {
    management_group_key = "regulated-apps-dev-mg"
    workload             = "DevTest"
    enabled              = true
    tags = {
      application      = "regulated-apps-workload7"
      env              = "dev"
      environment_type = "nonprod"
      workload_domain  = "regulated-apps"
    }
  }
  "regulated-apps-dev-workload8-sub" = {
    management_group_key = "regulated-apps-dev-mg"
    workload             = "DevTest"
    enabled              = true
    tags = {
      application      = "regulated-apps-workload8"
      env              = "dev"
      environment_type = "nonprod"
      workload_domain  = "regulated-apps"
    }
  }
  "regulated-apps-dev-workload9-sub" = {
    management_group_key = "regulated-apps-dev-mg"
    workload             = "DevTest"
    enabled              = true
    tags = {
      application      = "regulated-apps-workload9"
      env              = "dev"
      environment_type = "nonprod"
      workload_domain  = "regulated-apps"
    }
  }
  "regulated-apps-test-workload7-sub" = {
    management_group_key = "regulated-apps-test-mg"
    workload             = "DevTest"
    enabled              = true
    tags = {
      application      = "regulated-apps-workload7"
      env              = "test"
      environment_type = "nonprod"
      workload_domain  = "regulated-apps"
    }
  }
  "regulated-apps-test-workload8-sub" = {
    management_group_key = "regulated-apps-test-mg"
    workload             = "DevTest"
    enabled              = true
    tags = {
      application      = "regulated-apps-workload8"
      env              = "test"
      environment_type = "nonprod"
      workload_domain  = "regulated-apps"
    }
  }
  "regulated-apps-test-workload9-sub" = {
    management_group_key = "regulated-apps-test-mg"
    workload             = "DevTest"
    enabled              = true
    tags = {
      application      = "regulated-apps-workload9"
      env              = "test"
      environment_type = "nonprod"
      workload_domain  = "regulated-apps"
    }
  }
  "regulated-apps-prod-workload7-sub" = {
    management_group_key = "regulated-apps-prod-mg"
    workload             = "Production"
    enabled              = true
    tags = {
      application      = "regulated-apps-workload7"
      env              = "prod"
      environment_type = "prod"
      workload_domain  = "regulated-apps"
    }
  }
  "regulated-apps-prod-workload8-sub" = {
    management_group_key = "regulated-apps-prod-mg"
    workload             = "Production"
    enabled              = true
    tags = {
      application      = "regulated-apps-workload8"
      env              = "prod"
      environment_type = "prod"
      workload_domain  = "regulated-apps"
    }
  }
  "regulated-apps-prod-workload9-sub" = {
    management_group_key = "regulated-apps-prod-mg"
    workload             = "Production"
    enabled              = true
    tags = {
      application      = "regulated-apps-workload9"
      env              = "prod"
      environment_type = "prod"
      workload_domain  = "regulated-apps"
    }
  }

  "APIM-dev-sub" = {
    management_group_key = "shared-services-dev-mg"
    workload             = "DevTest"
    enabled              = true
    tags = {
      application      = "APIM"
      env              = "dev"
      environment_type = "nonprod"
      workload_domain  = "shared-services"
    }
  }
  "APIM-test-sub" = {
    management_group_key = "shared-services-test-mg"
    workload             = "DevTest"
    enabled              = true
    tags = {
      application      = "APIM"
      env              = "test"
      environment_type = "nonprod"
      workload_domain  = "shared-services"
    }
  }
  "APIM-prod-sub" = {
    management_group_key = "shared-services-prod-mg"
    workload             = "Production"
    enabled              = true
    tags = {
      application      = "APIM"
      env              = "prod"
      environment_type = "prod"
      workload_domain  = "shared-services"
    }
  }
  "enterprise-scheduler-dev-sub" = {
    management_group_key = "shared-services-dev-mg"
    workload             = "DevTest"
    enabled              = true
    tags = {
      application      = "enterprise-scheduler"
      env              = "dev"
      environment_type = "nonprod"
      workload_domain  = "shared-services"
    }
  }
  "enterprise-scheduler-test-sub" = {
    management_group_key = "shared-services-test-mg"
    workload             = "DevTest"
    enabled              = true
    tags = {
      application      = "enterprise-scheduler"
      env              = "test"
      environment_type = "nonprod"
      workload_domain  = "shared-services"
    }
  }
  "enterprise-scheduler-prod-sub" = {
    management_group_key = "shared-services-prod-mg"
    workload             = "Production"
    enabled              = true
    tags = {
      application      = "enterprise-scheduler"
      env              = "prod"
      environment_type = "prod"
      workload_domain  = "shared-services"
    }
  }
  "data-platform-dev-sub" = {
    management_group_key = "shared-services-dev-mg"
    workload             = "DevTest"
    enabled              = true
    tags = {
      application      = "data-platform"
      env              = "dev"
      environment_type = "nonprod"
      workload_domain  = "shared-services"
    }
  }
  "data-platform-test-sub" = {
    management_group_key = "shared-services-test-mg"
    workload             = "DevTest"
    enabled              = true
    tags = {
      application      = "data-platform"
      env              = "test"
      environment_type = "nonprod"
      workload_domain  = "shared-services"
    }
  }
  "data-platform-prod-sub" = {
    management_group_key = "shared-services-prod-mg"
    workload             = "Production"
    enabled              = true
    tags = {
      application      = "data-platform"
      env              = "prod"
      environment_type = "prod"
      workload_domain  = "shared-services"
    }
  }
  "messaging-dev-sub" = {
    management_group_key = "shared-services-dev-mg"
    workload             = "DevTest"
    enabled              = true
    tags = {
      application      = "messaging"
      env              = "dev"
      environment_type = "nonprod"
      workload_domain  = "shared-services"
    }
  }
  "messaging-test-sub" = {
    management_group_key = "shared-services-test-mg"
    workload             = "DevTest"
    enabled              = true
    tags = {
      application      = "messaging"
      env              = "test"
      environment_type = "nonprod"
      workload_domain  = "shared-services"
    }
  }
  "messaging-prod-sub" = {
    management_group_key = "shared-services-prod-mg"
    workload             = "Production"
    enabled              = true
    tags = {
      application      = "messaging"
      env              = "prod"
      environment_type = "prod"
      workload_domain  = "shared-services"
    }
  }

  "sandbox-ops-sub" = {
    management_group_key = "sandbox-mg"
    workload             = "DevTest"
    tags = {
      application      = "sandbox-ops"
      env              = "sandbox"
      environment_type = "sandbox"
      workload_domain  = "sandbox"
    }
  }
  "sandbox-developer-sub" = {
    management_group_key = "sandbox-mg"
    workload             = "DevTest"
    tags = {
      application      = "sandbox-developer"
      env              = "sandbox"
      environment_type = "sandbox"
      workload_domain  = "sandbox"
    }
  }
  "sandbox-data-sub" = {
    management_group_key = "sandbox-mg"
    workload             = "DevTest"
    tags = {
      application      = "sandbox-data"
      env              = "sandbox"
      environment_type = "sandbox"
      workload_domain  = "sandbox"
      data_purpose     = "experimentation-only"
    }
  }
  "sandbox-architect-sub" = {
    management_group_key = "sandbox-mg"
    workload             = "DevTest"
    tags = {
      application      = "sandbox-architect"
      env              = "sandbox"
      environment_type = "sandbox"
      workload_domain  = "sandbox"
    }
  }
  "decommissioned-sub" = {
    management_group_key = "decommissioned-mg"
    workload             = "Production"
    tags = {
      application      = "decommissioned"
      env              = "decommissioned"
      environment_type = "decommissioned"
      workload_domain  = "decommissioned"
    }
  }
}
