# Platform Identity Root

This root creates shared identity and security foundations for a landing-zone environment.

Key Vault is RBAC-first and private-by-default. Access assignments, diagnostics, and private endpoint attachment are composed explicitly so ownership and approval remain visible.

For smoke tests, `key_vault_private_endpoint` is left `null` so this root can validate the identity/vault baseline without requiring hub private DNS outputs. For enterprise testing, attach the private endpoint to the approved private endpoint subnet and pass the Key Vault private DNS zone ID from `platform-connectivity`.

Keep live secret values, certificate private keys, break-glass credentials, and one-time operational recovery material outside Terraform state. Terraform should manage vaults, RBAC, private endpoints, diagnostics, and policy; controlled secret injection should use approved secret-management or CI/CD release processes.
