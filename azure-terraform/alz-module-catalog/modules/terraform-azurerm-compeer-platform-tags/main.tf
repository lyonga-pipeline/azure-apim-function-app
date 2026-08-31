locals {
  default_tags = {
    env                 = var.environment
    application         = var.application
    created_by          = var.created_by
    bt_owner            = var.business_owner
    source_repo         = var.source_repo
    tf_workspace        = var.terraform_workspace
    recovery            = var.recovery_tier
    cost_center         = var.cost_center
    data_classification = var.data_classification
    compliance_boundary = var.compliance_boundary
  }

  # Drop null / empty values so a caller that omits an optional tag does not
  # produce an empty tag on every resource.
  tags = merge(
    { for key, value in local.default_tags : key => value if value != null && value != "" },
    var.additional_tags,
  )
}

output "tags" {
  description = "Normalized enterprise tag map (frozen key names - consumed by every pattern)."
  value       = local.tags
}
