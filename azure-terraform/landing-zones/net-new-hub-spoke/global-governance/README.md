# Global Governance Root

This root creates the management-group scaffold and subscription placement for the net-new landing-zone path.

It receives IDs explicitly from HCP workspace variables or an approved governance catalog. It does not read legacy remote state or infer subscription placement from environment names.

For a test tenant, leave `root_management_group_id` unset or blank. Terraform will create the top-level management groups directly under the tenant root. If you set `root_management_group_id`, the referenced parent management group must already exist in the same tenant and the HCP run identity must have permission to create children below it.

In HCP Terraform, set `root_management_group_id` as a Terraform workspace variable, not an environment variable. If you prefer an environment variable, its key must be `TF_VAR_root_management_group_id`. The value can be a management group name like `compeer-root`, a tenant-root management group GUID, or a full Azure management group resource ID such as `/providers/Microsoft.Management/managementGroups/compeer-root`. The root normalizes short names to the full Azure resource ID before passing them to AzureRM.

For a personal-account smoke test, prefer leaving `root_management_group_id` unset or blank unless you specifically want to create the landing-zone management groups under an existing parent management group. Do not set this to a subscription ID.

The error `Parent management group 'compeer-root' not found` means the configured parent ID does not exist in the Azure tenant used by the HCP workspace. Either create/import that parent first, or leave `root_management_group_id` unset or blank for the smoke test.

The root supports both individual Azure Policy definitions and policy set definitions/initiatives. Use policy set definitions for the baseline landing-zone initiative so approved regions, required tags, public access, encryption, diagnostics, identity, and connectivity guardrails can be assigned as one scoped package at the net-new landing-zone management group.

This root is expected to pass the current OPA landing-zone workload policy because it deploys governance controls rather than workload/PaaS resources. Use Azure Policy for runtime guardrails and OPA for plan-time review of workload/platform deployment plans.

Before production promotion, align the Azure Policy required tag names with the platform tag module and OPA data file. The current platform tag standard uses `env`, `bt_owner`, `source_repo`, `tf_workspace`, and `recovery`; the sample Azure Policy assignment currently demonstrates a more verbose alternate naming set.
