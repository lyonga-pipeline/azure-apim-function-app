output "tags" {
  description = "Normalized enterprise tag map - only the tags the caller supplied a value for, plus additional_tags. Frozen key names."
  value       = local.tags
}

output "missing_mandatory" {
  description = "Mandatory (Required=Yes) tags not supplied by the caller. Empty when all are set. A caller can precondition on this to enforce them."
  value       = local.missing_mandatory
}
