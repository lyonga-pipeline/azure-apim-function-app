output "names" {
  description = "Resource name per type, `<abbr>-<org>-<workload>-<env>-<region>-<instance>`."
  value       = local.names
}

output "names_nodash" {
  description = "Compacted names (<=24 chars) for storage accounts / key vaults / other no-separator resources."
  value       = local.names_nodash
}

output "base" {
  description = "The shared name stem without a type abbreviation."
  value       = local.base
}

output "region_short" {
  description = "Resolved region short code."
  value       = local.rs
}
