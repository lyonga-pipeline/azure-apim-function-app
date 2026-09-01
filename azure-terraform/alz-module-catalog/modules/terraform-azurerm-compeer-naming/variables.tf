variable "org" {
  description = "Org / tenant short code, e.g. cmp."
  type        = string
  default     = "cmp"
}

variable "workload" {
  description = "Workload / platform slice short code, e.g. hub, mgmt, appalpha."
  type        = string
}

variable "environment" {
  description = "Environment short code: prod | test | dev | np | shared."
  type        = string

  validation {
    condition     = contains(["prod", "test", "dev", "np", "shared", "sbx"], var.environment)
    error_message = "environment must be prod, test, dev, np, shared, or sbx."
  }
}

variable "region" {
  description = "Azure region long name (e.g. centralus) - mapped to a short code."
  type        = string
  default     = "centralus"
}

variable "region_short_overrides" {
  description = "Extra region long->short mappings merged over the built-in table."
  type        = map(string)
  default     = {}
}

variable "instance" {
  description = "Instance discriminator, zero-padded, e.g. \"001\"."
  type        = string
  default     = "001"
}

variable "separator" {
  description = "Token separator for names that allow one."
  type        = string
  default     = "-"
}
