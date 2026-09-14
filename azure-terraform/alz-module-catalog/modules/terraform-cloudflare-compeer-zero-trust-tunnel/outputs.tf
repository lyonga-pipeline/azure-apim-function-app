output "id" {
  description = "ID of the Cloudflare Zero Trust tunnel."
  value       = cloudflare_zero_trust_tunnel_cloudflared.tunnel.id
}

output "name" {
  description = "Name of the Cloudflare Zero Trust tunnel."
  value       = cloudflare_zero_trust_tunnel_cloudflared.tunnel.name
}

output "cname" {
  description = "CNAME target for the tunnel, used in DNS records that route traffic through it."
  value       = cloudflare_zero_trust_tunnel_cloudflared.tunnel.cname
}

output "tunnel_token" {
  description = "Token used by cloudflared to run this tunnel (sensitive)."
  value       = cloudflare_zero_trust_tunnel_cloudflared.tunnel.tunnel_token
  sensitive   = true
}

output "config_id" {
  description = "ID of the tunnel configuration resource."
  value       = cloudflare_zero_trust_tunnel_cloudflared_config.tunnel_config.id
}

output "dns_record_ids" {
  description = "Map of caller-supplied key to Cloudflare DNS record ID routed through the tunnel."
  value       = { for key, value in cloudflare_record.record : key => value.id }
}

output "access_application_ids" {
  description = "Map of caller-supplied key to Cloudflare Access application ID."
  value       = { for key, value in cloudflare_zero_trust_access_application.access_application : key => value.id }
}

output "access_policy_ids" {
  description = "Map of caller-supplied key to Cloudflare Access policy ID."
  value       = { for key, value in cloudflare_zero_trust_access_policy.access_policy : key => value.id }
}
