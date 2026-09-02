output "id" {
  description = "ID of the Cloudflare Zero Trust tunnel."
  value       = cloudflare_zero_trust_tunnel_cloudflared.this.id
}

output "name" {
  description = "Name of the Cloudflare Zero Trust tunnel."
  value       = cloudflare_zero_trust_tunnel_cloudflared.this.name
}

output "cname" {
  description = "CNAME target for the tunnel, used in DNS records that route traffic through it."
  value       = cloudflare_zero_trust_tunnel_cloudflared.this.cname
}

output "tunnel_token" {
  description = "Token used by cloudflared to run this tunnel (sensitive)."
  value       = cloudflare_zero_trust_tunnel_cloudflared.this.tunnel_token
  sensitive   = true
}

output "config_id" {
  description = "ID of the tunnel configuration resource."
  value       = cloudflare_zero_trust_tunnel_cloudflared_config.this.id
}

output "dns_record_ids" {
  description = "Map of caller-supplied key to Cloudflare DNS record ID routed through the tunnel."
  value       = { for key, value in cloudflare_record.this : key => value.id }
}

output "access_application_ids" {
  description = "Map of caller-supplied key to Cloudflare Access application ID."
  value       = { for key, value in cloudflare_zero_trust_access_application.this : key => value.id }
}

output "access_policy_ids" {
  description = "Map of caller-supplied key to Cloudflare Access policy ID."
  value       = { for key, value in cloudflare_zero_trust_access_policy.this : key => value.id }
}
