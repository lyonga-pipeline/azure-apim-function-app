variable "subscription_id" {
  type        = string
  description = "Execution subscription used to write the catalog state."
}

variable "target_subscriptions" {
  type = map(object({
    management_group_key      = string
    existing_subscription_id  = string
    subscription_display_name = optional(string)
  }))
  description = "Subscription catalog keyed by logical landing-zone role. existing_subscription_id may be left blank in the sample catalog until the real subscription is assigned."
  default     = {}
}
