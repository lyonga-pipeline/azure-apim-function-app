# Compeer Cloudflare Connectors Pattern

## Overview

**Rollout status:** Windows Server 2022 Datacenter Gen2 and managed bootstrap
are supported. The Compeer root selects Windows explicitly. Legacy Linux
inputs retain their original resource addresses; changing an existing key's
OS requires a reviewed replacement, never a blind state move.
See the [edge and tunnel standard](../terraform-cloudflare-compeer-edge-baseline/README.md)
for prerequisites, token handoff, rollout stages and acceptance gates.

**What this deploys:** the hub-hosted VMs intended to run the Cloudflare Tunnel
daemon (`cloudflared`), giving the "all inbound traffic through Cloudflare
Tunnels" posture (see `platform-policy`'s private-only-connectivity
guardrail) something to terminate onto inside Azure.

| Resource | Purpose |
|---|---|
| `azurerm_windows_virtual_machine.vm` | Windows 2022 Gen2 with secure boot, vTPM, automatic patching and managed boot diagnostics |
| `azurerm_virtual_machine_run_command.cloudflared` | Pinned/hash-verified installer, managed-identity token retrieval, service recovery and local tunnel-readiness gate |
| `azurerm_role_assignment.tunnel_token_reader` | System identity receives Key Vault Secrets User at the individual secret scope |
| `azurerm_virtual_machine_extension.domain_join` | Optional approved domain joining with sensitive OU-scoped credentials |
| `azurerm_linux_virtual_machine.vm` | The connector VM(s) — no public IP, SSH-key or password auth per `terraform_data.connector_contract` |
| `azurerm_virtual_machine_extension.extension` | Optional post-provision extension (e.g. a bootstrap script) |
| `module.management_locks` | Optional `CanNotDelete`/`ReadOnly` lock per resource |

**`terraform_data.connector_contract` — what it enforces:** every connector
must have input credentials for an auth method - an SSH-auth connector
needs a matching `admin_ssh_keys` entry, a password-auth connector needs a
matching `admin_passwords` entry. Without this contract, a misconfigured
connector could plan without login inputs. This does not verify network
reachability, authorized login, runtime installation or tunnel health. See
`tests/connector_contract.tftest.hcl` for the exact failure/pass scenarios.

---

## Windows Production Inputs

Set `connectors.<key>.os_type = "Windows"`, provide local admin passwords
through sensitive `admin_passwords`, and assign a system identity. The default
image is MicrosoftWindowsServer/WindowsServer/2022-datacenter-g2. With
`require_windows_runtime = true`, use an explicit image version or a
version-specific image resource ID; `latest` is rejected. Use D4s_v5 and
StandardSSD_LRS where following the network document.

Provide `windows_bootstrap.<key>` with release version (2025.4.0 or newer),
verified 64-hex SHA256, matching Key Vault ID/URI, existing runtime-token secret
name and rollout revision. No runtime token is an input. Vault RBAC must be
enabled, and the token secret must exist before secret-scoped role assignment.
The deployer needs resource creation plus scoped role-assignment permission.
The script retries secret retrieval for propagation delays, then fails closed.

Production requires two zones per token/secret group. Change version/hash/revision
on only one replica at a time; apply and verify before its peer. The bootstrap
uses Managed Run Command rather than an oversized encoded command or a second
Custom Script Extension. A startup task refreshes credentials after reboot;
routine rotations are explicit per-replica rollouts. Logs rotate locally and
metrics/readiness bind only to loopback. Configure central collection through
the Windows observability owner; do not expose the metrics port publicly.

Optional `domain_join` takes domain, domain-qualified username, password_key
and ou_path. Supply `domain_join_passwords` through sensitive workspace inputs.
Domain join precedes other extensions/bootstrap. Administrator and domain-join
passwords remain in Terraform state; enforce restricted backend access.

## Existing Hub Integration

The deployment root accepts `hub_workspaces` and resolves each connector's
`hub_key`/`subnet_key` from public producer outputs. It checks that the subnet
belongs to the published hub VNet and the deployment subscription. Different
hub subscriptions require separate deployments of the same root. This pattern
does not create or adopt Hub VNets/subnets, routes, or firewall policies.

Use `phase2_agents` in the root for Windows AMA and DCR associations. Keep a
single owner if Azure Policy already installs AMA. Confirm MDE onboarding with
the Defender for Servers/policy owner; it is not safe to duplicate that
extension without tenant onboarding details. Confirm licensing before setting
Windows_Server Hybrid Benefit. Select actual domain OU, monitoring IDs,
security approvals and firewall permits rather than guessed defaults.

It does not own Cloudflare tunnels, DNS, Access policy, WAF, or account settings.
Use the edge release helper to synchronize tokens to Key Vault before applying
the Windows runtime profile. A successful local bootstrap is not external
application, authorization or failover acceptance. Test in nonprod before
production and retain the evidence described in the linked standard.
