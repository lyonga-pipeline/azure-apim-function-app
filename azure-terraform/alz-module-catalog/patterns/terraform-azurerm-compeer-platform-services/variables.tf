variable "resource_group_name" { type = string }
variable "location" {
  type    = string
  default = "centralus"
}
variable "tags" {
  type    = map(string)
  default = {}
}
# PHASE2 NEW: v5 8.1 PLT-03. Packer/Image Builder publishes separately versioned image versions.
variable "galleries" {
  type = map(object({
    name        = string
    description = optional(string, "Private approved golden-image gallery.")
    images = optional(map(object({
      name      = string
      os_type   = string
      publisher = string
      offer     = string
      sku       = string
    })), {})
  }))
  default = {}
  validation {
    condition = alltrue(concat(
      [for key in keys(var.galleries) : !strcontains(key, "/")],
      flatten([for gallery in values(var.galleries) : [for key in keys(gallery.images) : !strcontains(key, "/")]])
    ))
    error_message = "Gallery and image logical keys must not contain '/' (reserved stable-key separator)."
  }
  validation {
    condition     = alltrue(flatten([for gallery in values(var.galleries) : [for image in values(gallery.images) : contains(["Windows", "Linux"], image.os_type)]]))
    error_message = "Golden-image definitions must declare Windows or Linux."
  }
}
# PHASE2 NEW: v5 8.2 PLT-04. No SCCM/VM patch-mode changes are made implicitly.
variable "patch_schedules" {
  type = map(object({
    name                         = string
    start_date_time              = string
    time_zone                    = string
    recur_every                  = string
    duration                     = optional(string, "03:00")
    reboot                       = optional(string, "IfRequired")
    windows_classifications      = optional(list(string), ["Critical", "Security"])
    linux_classifications        = optional(list(string), ["Critical", "Security"])
    approved_change_id           = string
    azure_patch_mode_ready       = bool
    mutually_exclusive_with_sccm = bool
    virtual_machines             = map(string)
  }))
  default = {}
  validation {
    condition = alltrue(concat(
      [for key in keys(var.patch_schedules) : !strcontains(key, "/")],
      flatten([for schedule in values(var.patch_schedules) : [for key in keys(schedule.virtual_machines) : !strcontains(key, "/")]])
    ))
    error_message = "Schedule and VM logical keys must not contain '/' (reserved stable-key separator)."
  }
  validation {
    condition = alltrue([for schedule in values(var.patch_schedules) :
      length(trimspace(schedule.approved_change_id)) > 0 && schedule.azure_patch_mode_ready &&
      schedule.mutually_exclusive_with_sccm && length(schedule.virtual_machines) > 0 &&
      contains(["IfRequired", "Always", "Never"], schedule.reboot)
    ])
    error_message = "Update Manager requires change approval, compatible VM patch mode, explicit SCCM exclusion and non-empty stable-key VM assignments."
  }
}
