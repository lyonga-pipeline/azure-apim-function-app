# Windows Cloudflare Connector Deployment

This root deploys the four planned connector VMs using **Windows Server 2022
Datacenter Gen2**. `terraform.tfvars` contains the actual deployment shape;
it remains disabled until approved tenant values are supplied. Do not enable
it with placeholders or treat successful mock tests as live certification.

See the [enterprise edge/tunnel standard](../../../../patterns/terraform-cloudflare-compeer-edge-baseline/README.md)
for account security, publication, credentials, rollout challenges and the
full acceptance runbook.

## Existing Hubs, Not New Networks

Each connector chooses `hub_key` and `subnet_key`. The root reads the selected
producer's public `hub_virtual_network_id` and `subnet_ids` outputs, then checks
that the subnet belongs to that hub. It neither creates nor imports a VNet.
Approve producer output access for this consumer in HCP Terraform.

For two existing hubs, extend the root's existing map:

```hcl
hub_workspaces = {
  primary   = { organization = "Compeer-Financial-Services", workspace = "ACTUAL_PRIMARY_HUB_WORKSPACE" }
  secondary = { organization = "Compeer-Financial-Services", workspace = "ACTUAL_SECONDARY_HUB_WORKSPACE" }
}
```

Change a connector's `hub_key` to `secondary` and its `subnet_key` to the actual
key exported by that producer. Do not paste VNet IDs into the pattern. The root
rejects a subnet in a different subscription from its Azure provider: deploy
this same root separately per subscription if hubs cross subscriptions. Keep
one VM/NIC owner and include only that subscription's connector entries.
NICs must also be in the VNet's Azure region; select a matching root location.

The inventory currently uses the single-hub document layout and reserved
10.102.3.4-7 addresses. Confirm IPAM for the selected hub; do not reuse these
addresses in another hub merely because its subnet has the same label.

## Required Values Before Enabling

| Value | Where to obtain it |
|---|---|
| `tenant_id`, `subscription_id` and Azure OIDC configuration | Approved HCP variable set/workspace deployment identity |
| Actual producer workspace names and subnet keys | Deployed Hub owners/HCP public outputs |
| `windows_image_version` | Approved Azure image inventory, not a guessed version |
| `admin_passwords` keyed np01/np02/prod01/prod02 | Sensitive HCP variables; generate through approved secret handling |
| `common_domain_join.username`, optional OU, `domain_join_passwords` | Domain services team; use an OU-scoped join account |
| `windows_bootstrap` entry for each VM | Approved cloudflared version/hash and existing Key Vault token references |
| `phase2_agents` entry for each VM and ownership confirmation | Monitoring owner: Windows DCR, UAMI and optional private DCE/AMPLS |
| IdP/Access/WAF configuration, token synchronization and acceptance | Edge/security workspace owners |
| Panorama, NSG, UDR, DNS and permitted outbound 7844 paths | Network/firewall owners |
| Defender for Servers and Windows MDE onboarding | Existing security/policy owner; avoid a second extension owner |

List candidate image versions, then select the approved release:

```sh
az vm image list --location centralus --publisher MicrosoftWindowsServer \
  --offer WindowsServer --sku 2022-datacenter-g2 --all --query '[].version' -o tsv
```

Set `windows_image_version` to an actual version from that list. The production
profile rejects `latest`. Confirm availability of the VM size, zones, host
encryption and Trusted Launch in the target subscription. Set per-VM
`license_type = "Windows_Server"` only after confirming Hybrid Benefit rights;
omitting it uses the normal Azure Windows licensing model.

## Runtime Token and Bootstrap

First create the named tunnels in the edge workspace with publication DNS
empty. Run the edge `scripts/tunnel_release.py sync-token` helper from an
approved OIDC release agent to populate an RBAC-enabled Key Vault. Runtime
tokens are distinct from the Cloudflare API token and raw tunnel secret.

Populate all four `windows_bootstrap` entries in the existing tfvars object:

```hcl
np01 = {
  cloudflared_version = "ACTUAL_APPROVED_RELEASE"
  binary_sha256       = "ACTUAL_VERIFIED_64_HEX_SHA256"
  key_vault_id        = "ACTUAL_EXISTING_KEY_VAULT_RESOURCE_ID"
  key_vault_uri       = "https://ACTUAL_VAULT_NAME.vault.azure.net"
  token_secret_name   = "cloudflare-nonprod-token"
  rollout_revision    = "initial-np01"
}
```

Use the same nonprod token reference for np01/np02 and a distinct prod token
reference for prod01/prod02. The production contract requires two zones per
secret group. Secret-scoped RBAC assignments require the secret to exist first.
The Azure deployer needs scoped role-assignment privileges; VMs receive only
Key Vault Secrets User on the individual secret.

Bootstrap runs under the VM agent through Managed Run Command after domain
join and declared extensions. It verifies binary SHA256, fetches the runtime
token using system identity, protects files, installs/configures the Windows
service, configures recovery and startup refresh, and waits for local `/ready`.
It does not fetch the Cloudflare API token. Metrics bind to loopback; local
logs rotate. The script and non-secret references are in state, but the fetched
runtime token is not a Terraform input/output of this root. Administrator and
domain-join passwords still require protected state access.

For AMA, add the monitoring UAMI to each VM's existing identity, preserving
SystemAssigned, and set `phase2_agents.<key>.os_type = "Windows"`. Populate
actual approved DCR/DCE references. The production root requires every VM to
have a monitoring entry. Reuse policy-owned AMA with `install_agent = false`
and confirmed ownership; do not create duplicate agents/associations. Central
cloudflared log collection and alert delivery still need configured DCR/export
and operational evidence, not just an AMA extension.

## Controlled Release

1. Populate inputs and confirm domain, Defender, monitoring and network ownership.
2. Synchronize nonprod/prod runtime tokens to their separate vault secrets.
3. Review a saved plan. Run the edge helper's `check-rollout PLAN.json` step before applying.
4. Apply the approved plan, verify two replicas per tunnel, and run origin/authentication/failover tests.
5. Publish DNS only after acceptance. Record reboot, patch and recovery evidence.

Subsequent upgrades/rotations change one replica's version/hash/revision at a
time. Verify it before changing its peer. The rollout-plan helper rejects two
existing replicas changing in the same tunnel stage and Windows VM replacement.
Use separate reviewed cutover procedures for intentional replacement. Protect
plan JSON as secret-bearing material; never commit or log it. Use an approved
Update Manager/maintenance process for OS patching so both replicas are not
rebooted together.

## Compatibility and Verification

The shared pattern retains legacy Linux addresses when `os_type` is omitted;
this root's new inventory explicitly uses Windows. No Linux-to-Windows state
move or replacement is performed automatically. With new VMs, do not import
unrelated VM state.

Run `terraform validate`, `terraform test`, and
`terraform test -test-directory=phase2-tests` after initialization. Mock tests
cover producer resolution, OS/monitoring matching, bootstrap references and
guards. They do not execute Windows services or validate live tenant policies.
