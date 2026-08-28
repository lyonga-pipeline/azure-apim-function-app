output "id" {
  value = cloudflare_zero_trust_tunnel_cloudflared.this.id
}

output "name" {
  value = cloudflare_zero_trust_tunnel_cloudflared.this.name
}

output "cname" {
  value = cloudflare_zero_trust_tunnel_cloudflared.this.cname
}

output "tunnel_token" {
  value     = cloudflare_zero_trust_tunnel_cloudflared.this.tunnel_token
  sensitive = true
}

output "config_id" {
  value = cloudflare_zero_trust_tunnel_cloudflared_config.this.id
}

output "dns_record_ids" {
  value = { for key, value in cloudflare_record.this : key => value.id }
}

output "access_application_ids" {
  value = { for key, value in cloudflare_zero_trust_access_application.this : key => value.id }
}

output "access_policy_ids" {
  value = { for key, value in cloudflare_zero_trust_access_policy.this : key => value.id }
}
