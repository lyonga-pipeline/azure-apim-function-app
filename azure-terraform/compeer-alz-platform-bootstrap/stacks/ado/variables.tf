variable "project_name" {
  description = "Existing Azure DevOps project to reuse."
  type        = string
}

variable "core_pipelines_repository" {
  description = "Existing ADO repository that hosts shared validation templates."
  type        = string
  default     = "Core/Pipelines"
}

variable "core_pipelines_ref" {
  description = "Ref for the shared Core/Pipelines repository. Pin to main or an approved tag/branch."
  type        = string
  default     = "refs/heads/iac_scan_templates"
}

variable "terraform_version" {
  type    = string
  default = "1.9.5"
}

variable "tflint_version" {
  type    = string
  default = "0.53.0"
}

variable "repositories" {
  description = "Platform ALZ repositories to create. Add entries to scale without module changes."
  type = map(object({
    name              = string
    description       = string
    repository_type   = optional(string, "terraform")
    create_pipeline   = optional(bool, true)
    pipeline_name     = optional(string)
    pipeline_yml_path = optional(string, "IAC-Build-Validation.yml")
    pipeline_folder   = optional(string, "\\ALZ")
    seed_directories  = optional(list(string), [])
  }))

  validation {
    condition = alltrue([
      for repo in values(var.repositories) : contains(["terraform", "opa"], repo.repository_type)
    ])
    error_message = "repository_type must be terraform or opa."
  }
}
