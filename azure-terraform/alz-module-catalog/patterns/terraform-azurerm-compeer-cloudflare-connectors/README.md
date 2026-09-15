# Compeer Cloudflare Connectors Pattern

## Overview

**What this deploys:** the hub-hosted VMs that run the Cloudflare Tunnel
daemon (`cloudflared`), giving the "all inbound traffic through Cloudflare
Tunnels" posture (see `platform-policy`'s private-only-connectivity
guardrail) something to terminate onto inside Azure.

| Resource | Purpose |
|---|---|
| `azurerm_linux_virtual_machine.vm` | The connector VM(s) — no public IP, SSH-key or password auth per `terraform_data.connector_contract` |
| `azurerm_virtual_machine_extension.extension` | Optional post-provision extension (e.g. a bootstrap script) |
| `module.management_locks` | Optional `CanNotDelete`/`ReadOnly` lock per resource |

**`terraform_data.connector_contract` — what it enforces:** every connector
must actually be reachable by *some* auth method — an SSH-auth connector
needs a matching `admin_ssh_keys` entry, a password-auth connector needs a
matching `admin_passwords` entry. Without this contract, a misconfigured
connector would silently plan and apply a VM nobody can log into. See
`tests/connector_contract.tftest.hcl` for the exact failure/pass scenarios.

---

This Azure pattern deploys the hub-hosted Cloudflare connector VM infrastructure: resource group, NICs with no public IPs, Linux VMs, optional VM extensions, optional diagnostics, optional RBAC, locks, and operational contracts.

It does not own Cloudflare tunnels, DNS, Access policy, WAF, or account settings. Those are handled by the Cloudflare edge workspace where approved. Connector runtime tokens should be injected through sensitive workspace variables or an external configuration-management process.
