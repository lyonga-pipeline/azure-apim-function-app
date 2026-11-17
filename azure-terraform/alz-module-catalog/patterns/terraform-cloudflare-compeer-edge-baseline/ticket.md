# Provision Cloudflare Automation Credentials for Landing Zone Edge

## Description
Provision an account-owned Cloudflare API token (service principal) for Compeer's
edge Terraform workspace, scoped to approved accounts/zones. Explicitly grant
permissions to create, read/list, update, and delete the managed resources:

| Scope | Permission | Resources |
| --- | --- | --- |
| Account | Cloudflare Tunnel: Edit | Tunnels and ingress configuration |
| Account | Access: Apps and Policies: Edit | Access applications and policies |
| Zone | DNS: Edit | Application and tunnel DNS records |
| Zone | Zone WAF: Edit | Zone-level custom and managed WAF rulesets |
| Account | Account WAF: Edit | Account-level WAF rulesets, only if configured |
| Zone | Zone: Read | Existing zone metadata |

Add phase-specific ruleset permissions only where configured (for example,
Transform Rules). Grant Zone: Edit only if Terraform is approved to manage zones;
otherwise reuse existing zones. No Azure SP, Global API Key, or Access service
token is needed for these Cloudflare management operations.

## Acceptance Criteria
- [ ] Account-owned token has the above permissions for enabled resources only;
      approved account/zone scope and owner team are recorded without secret values.
- [ ] Store as sensitive environment variable `CLOUDFLARE_API_TOKEN` in the edge
      HCP workspace; never place the value in Git, tfvars, tickets, or logs.
- [ ] Plan and approved test apply verify resource reads, creation, updates, and
      deletion of disposable test resources without permission errors.
- [ ] Document expiration, rotation/revocation owner, and recovery procedure.
- [ ] Keep connector tunnel tokens and Azure deployment identities separate.

Reference: [Cloudflare account-owned API tokens](https://developers.cloudflare.com/fundamentals/api/get-started/account-owned-tokens/).
Permissions: [Cloudflare API permissions](https://developers.cloudflare.com/fundamentals/api/reference/permissions/).
