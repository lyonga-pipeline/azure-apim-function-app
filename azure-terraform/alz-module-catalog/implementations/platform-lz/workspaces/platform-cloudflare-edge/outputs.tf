output "zone_ids" {
  value = module.cloudflare_edge.zone_ids
}

output "record_ids" {
  value = module.cloudflare_edge.record_ids
}

output "ruleset_ids" {
  value = module.cloudflare_edge.ruleset_ids
}

output "tunnel_ids" {
  value = module.cloudflare_edge.tunnel_ids
}

output "tunnel_cnames" {
  value = module.cloudflare_edge.tunnel_cnames
}

output "tunnel_tokens" {
  value     = module.cloudflare_edge.tunnel_tokens
  sensitive = true
}

output "tunnel_dns_record_ids" {
  value = module.cloudflare_edge.tunnel_dns_record_ids
}

output "access_application_ids" {
  value = module.cloudflare_edge.access_application_ids
}

output "access_policy_ids" {
  value = module.cloudflare_edge.access_policy_ids
}
