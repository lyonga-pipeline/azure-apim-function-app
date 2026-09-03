locals {
  # Full enterprise tag vocabulary. Emitted key names are frozen - they are the
  # tag keys applied to every resource.
  candidate = {
    environment           = var.environment
    application           = var.application
    owner                 = var.owner
    source_repo           = var.source_repo
    created_on            = var.created_on
    criticality_tier      = var.criticality_tier
    data_classification   = var.data_classification
    lifecycle_state       = var.lifecycle_state
    cost_center           = var.cost_center
    gl_category           = var.gl_category
    application_component = var.application_component
    modified_on           = var.modified_on
    created_by            = var.created_by
    dr_tier               = var.dr_tier
    expiration_date       = var.expiration_date
  }

  mandatory_keys = [
    "environment", "application", "owner", "source_repo", "created_on",
    "criticality_tier", "data_classification", "lifecycle_state",
    "cost_center", "gl_category",
  ]

  # Drop any tag the caller left unset so an omitted optional tag does not
  # produce an empty tag on every resource.
  tags = merge(
    { for key, value in local.candidate : key => value if value != null && value != "" },
    var.additional_tags,
  )

  missing_mandatory = [for key in local.mandatory_keys : key if !contains(keys(local.tags), key)]
}
