# Compeer Cloudflare Edge Baseline

Creates the Cloudflare-owned edge/control-plane resources for the external-app ingress path: zones, DNS records, rulesets, Zero Trust tunnels, remotely managed tunnel ingress, and optional Access applications/policies.

Connector VMs are deployed from the Azure `platform-cloudflare-connectors` workspace. Keep tunnel secrets in HCP sensitive variables and import existing Cloudflare resources before assigning Terraform ownership.
