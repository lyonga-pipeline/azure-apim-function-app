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

  optional_tags = {
    creation_date = var.creation_date_utc
    last_modified = var.last_modified_utc
  }

  tags = merge(
    { for key, value in local.default_tags : key => value if value != null && value != "" },
    { for key, value in local.optional_tags : key => value if value != null && value != "" },
    var.additional_tags,
  )
}

output "tags" {
  description = "Normalized tag map for enterprise resources."
  value       = local.tags
}
