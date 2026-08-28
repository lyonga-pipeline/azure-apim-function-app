output "zone_ids" {
  description = "Cloudflare zone IDs keyed by input key."
  value       = { for key, zone in cloudflare_zone.this : key => zone.id }
}

output "record_ids" {
  description = "Cloudflare record IDs keyed by input key."
  value       = { for key, record in cloudflare_record.this : key => record.id }
}

output "ruleset_ids" {
  description = "Cloudflare ruleset IDs keyed by input key."
  value       = { for key, ruleset in cloudflare_ruleset.this : key => ruleset.id }
}

output "tunnel_ids" {
  description = "Cloudflare Zero Trust tunnel IDs keyed by tunnel key."
  value       = { for key, tunnel in module.zero_trust_tunnels : key => tunnel.id }
}

output "tunnel_cnames" {
  description = "Cloudflare Zero Trust tunnel CNAMEs keyed by tunnel key."
  value       = { for key, tunnel in module.zero_trust_tunnels : key => tunnel.cname }
}

output "tunnel_tokens" {
  description = "Sensitive Cloudflare Tunnel runtime tokens keyed by tunnel key."
  value       = { for key, tunnel in module.zero_trust_tunnels : key => tunnel.tunnel_token }
  sensitive   = true
}

output "tunnel_dns_record_ids" {
  description = "Tunnel-managed DNS record IDs by tunnel key."
  value       = { for key, tunnel in module.zero_trust_tunnels : key => tunnel.dns_record_ids }
}

output "access_application_ids" {
  description = "Tunnel Access application IDs by tunnel key."
  value       = { for key, tunnel in module.zero_trust_tunnels : key => tunnel.access_application_ids }
}

output "access_policy_ids" {
  description = "Tunnel Access policy IDs by tunnel key."
  value       = { for key, tunnel in module.zero_trust_tunnels : key => tunnel.access_policy_ids }
}
