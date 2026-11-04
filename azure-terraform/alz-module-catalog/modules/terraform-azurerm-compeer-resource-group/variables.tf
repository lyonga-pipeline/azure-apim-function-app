variable "resource_groups" {
  description = "Resource groups to create, keyed by a stable caller-owned identifier."
  type = map(object({
    name     = string
    location = string
    tags     = optional(map(string), {})
  }))

  validation {
    condition     = length(var.resource_groups) > 0
    error_message = "resource_groups must contain at least one resource group."
  }

  validation {
    condition = alltrue([
      for key in keys(var.resource_groups) :
      key == trimspace(key) && can(regex("^[A-Za-z0-9][A-Za-z0-9_-]*$", key))
    ])
    error_message = "resource_groups keys must be stable non-empty identifiers containing only letters, digits, hyphens, or underscores, and must start with a letter or digit."
  }

  validation {
    condition = alltrue([
      for group in values(var.resource_groups) :
      can(regex("^[-\\w._()]{1,90}$", group.name)) && !can(regex("\\.$", group.name))
    ])
    error_message = "Each resource group name must be 1-90 chars of letters, digits, - _ . ( ), and not end with a period."
  }

  # Keep the deployed registry's region/legacy environment policy; add the spoke's test/sandbox aliases.
  validation {
    condition = alltrue([
      for group in values(var.resource_groups) :
      can(regex("(?i)(^|[-_])(cus|ncus)[-_](prod|dev|test|uat|np0|np1|np2|np3|dev-test|sandbox|sbx)([-_]|$)", group.name))
    ])
    error_message = "Each resource group name must include an approved <region>-<environment> token: region = cus or ncus; environment = prod, dev, test, uat, np0, np1, np2, np3, dev-test, sandbox or sbx."
  }

  validation {
    condition = length(distinct([
      for group in values(var.resource_groups) : lower(trimspace(group.name))
    ])) == length(var.resource_groups)
    error_message = "Each resource group name must be unique, case-insensitively."
  }

  validation {
    condition = alltrue([
      for group in values(var.resource_groups) :
      trimspace(group.location) != ""
    ])
    error_message = "Each resource group location must be non-empty."
  }
}
