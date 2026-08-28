# Compeer Cloudflare Connectors Pattern

This Azure pattern deploys the hub-hosted Cloudflare connector VM infrastructure: resource group, NICs with no public IPs, Linux VMs, optional VM extensions, optional diagnostics, optional RBAC, locks, and operational contracts.

It does not own Cloudflare tunnels, DNS, Access policy, WAF, or account settings. Those are handled by the Cloudflare edge workspace where approved. Connector runtime tokens should be injected through sensitive workspace variables or an external configuration-management process.
