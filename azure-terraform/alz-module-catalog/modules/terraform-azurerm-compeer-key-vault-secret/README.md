# Key Vault Secret Module

This companion module manages Key Vault secrets separately from the Key Vault resource.

## What Is Better

| Area | Reviewed Configuration Pattern | Improved Module Pattern |
| --- | --- | --- |
| Secret lifecycle | Secrets are often expected to be added to the vault module or handled manually. | Secrets have their own module and can change without changing the vault lifecycle. |
| Ownership | Vault owners and application secret owners can become mixed together. | Application roots can manage application-owned secrets while the platform owns the vault. |
| Reuse | Different apps often require different secret sets. | Uses a focused resource contract that can be repeated or wrapped by workload patterns. |

## Design Intent

Use this module when Terraform should manage a secret value or secret metadata. Do not place long-lived application secret rotation policy inside the core `key-vault` module.

For production usage, secret values should normally come from secure pipeline variables, HCP variable sets, or another approved secret source rather than committed tfvars.

