variable "workload_identities" {
  description = "OIDC workload identities for HCP Terraform and Azure DevOps."
  type = map(object({
    display_name            = string
    description             = optional(string)
    owners                  = optional(list(string), [])
    tags                    = optional(list(string), ["terraform", "landing-zone"])
    prevent_duplicate_names = optional(bool, true)
    sign_in_audience        = optional(string, "AzureADMyOrg")
    federated_credentials = optional(map(object({
      display_name = string
      description  = optional(string)
      issuer       = string
      subject      = string
      audiences    = optional(list(string), ["api://AzureADTokenExchange"])
    })), {})
  }))
  default = {}
}
