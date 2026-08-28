variable "cloudflare_edge" {
  description = "Cloudflare edge workspace configuration."
  type        = any
  default = {
    enabled = false
  }
}

variable "cloudflare_tunnel_secrets" {
  description = "Sensitive tunnel secrets keyed by tunnel key or cloudflare_edge.tunnels[*].tunnel_secret_key."
  type        = map(string)
  sensitive   = true
  default     = {}
}
