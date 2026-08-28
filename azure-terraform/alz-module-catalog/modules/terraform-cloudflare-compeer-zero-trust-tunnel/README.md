# Compeer Cloudflare Zero Trust Tunnel

Reusable Cloudflare Tunnel module for external-app publication. It models the tunnel, remote ingress configuration, optional DNS records, optional Access applications, and optional Access policies.

The tunnel secret is a separate sensitive input because changing it replaces the tunnel. Keep it in HCP Terraform sensitive variables or an approved secret store. The module appends a terminal `http_status:404` catch-all rule to every tunnel configuration.
