variable "project_id" { type = string }
variable "name" { type = string }
variable "default_branch" {
  type    = string
  default = "refs/heads/main"
}
variable "files" {
  description = "Files managed in the repository. Keys are repo-relative paths without a leading slash."
  type        = map(string)
  default     = {}
}
variable "create_pipeline" {
  type    = bool
  default = true
}
variable "pipeline_name" { type = string }
variable "pipeline_yml_path" {
  type    = string
  default = "IAC-Build-Validation.yml"
}
variable "pipeline_folder" {
  type    = string
  default = "\\ALZ"
}
