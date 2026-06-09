# Windows VM Extension Module

This module applies general Windows VM extensions separately from VM creation and other guest configuration concerns.

## What Is Better

| Area | Reviewed Configuration Pattern | Improved Module Pattern |
| --- | --- | --- |
| Extension lifecycle | Extensions can be bundled into the VM module. | Extension deployment is independent. |
| Workload variance | Monitoring, script, security, and agent extensions differ by app. | Each extension can be composed as needed. |
| Drift control | Extension updates should not change the VM resource. | Only the extension resource is planned. |

## Design Intent

This module owns:

- Windows VM extension deployment
- Publisher, type, version, settings, and protected settings

Use companion modules for:

- `windows-vm`
- `windows-vm-domain-join`
- `key-vault-secret`
- `diagnostic-settings`

## Why This Matters

VM extensions are operational add-ons. Keeping them separate lets teams patch or replace agents without changing the base VM lifecycle.

