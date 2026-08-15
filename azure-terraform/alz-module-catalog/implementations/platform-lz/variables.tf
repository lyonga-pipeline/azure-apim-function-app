variable "tenant_id" {
  description = "Microsoft Entra tenant ID used by the platform landing-zone deployment identity."
  type        = string
}

variable "execution_subscription_id" {
  description = "Subscription used by the provider for provider-level reads and operations that are not scoped to another subscription."
  type        = string
}

variable "location" {
  description = "Primary Azure region for regional platform resources."
  type        = string
  default     = "centralus"
}

variable "environment" {
  description = "Environment label used in common tags and names."
  type        = string
  default     = "prod"
}

variable "platform_tags" {
  description = "Enterprise tag contract applied by each platform composition."
  type = object({
    application         = string
    business_owner      = string
    source_repo         = string
    terraform_workspace = string
    recovery_tier       = string
    cost_center         = string
    data_classification = string
    compliance_boundary = string
    additional_tags     = optional(map(string), {})
  })
}

variable "subscription_vending" {
  description = "Subscription-vending catalog. Keep vending_enabled false until billing scope and tenant permissions are confirmed."
  type        = any
  default = {
    enabled           = false
    vending_enabled   = false
    billing_scope     = null
    management_groups = {}
    subscriptions     = {}
  }
}

variable "global_governance" {
  description = "Management-group hierarchy, subscription placement, policy assignment, custom role, RBAC, and budget composition."
  type        = any
  default = {
    enabled           = false
    management_groups = {}
  }
}

variable "platform_management" {
  description = "Management subscription resources such as logging, alerting, backup, audit storage, locks, and no-cost Defender/SOC posture contract."
  type        = any
  default = {
    enabled = false
  }
}

variable "platform_connectivity" {
  description = "Connectivity subscription resources such as hub VNet, DNS, NSG, route tables, load balancers, and Palo Alto routing contract."
  type        = any
  default = {
    enabled = false
  }
}

variable "platform_identity" {
  description = "Identity subscription resources such as identity resource group, platform identities, Key Vault, RBAC, diagnostics, and private endpoint handoff."
  type        = any
  default = {
    enabled = false
  }
}

variable "platform_hybrid_connectivity" {
  description = "ExpressRoute/on-premises connectivity contract and optional gateway resources."
  type        = any
  default = {
    enabled = false
  }
}

variable "palo_alto_hub" {
  description = "Optional Palo Alto VM-Series deployment. Disabled by default so no firewall compute is created until approved."
  type        = any
  default = {
    enabled = false
  }
}

variable "cloudflare_edge" {
  description = "Optional Cloudflare edge baseline. Disabled by default unless Cloudflare ownership and API token are approved."
  type        = any
  default = {
    enabled = false
  }
}

variable "network_peering" {
  description = "Optional hub/spoke peering composition for platform-managed spokes."
  type        = any
  default = {
    enabled  = false
    peerings = {}
  }
}

variable "workload_spoke" {
  description = "Optional pilot workload-spoke composition. Disabled by default because workload landing zones are owned separately."
  type        = any
  default = {
    enabled = false
  }
}
