# Compeer Platform Policy Pattern

This pattern owns Azure Policy definitions, initiatives, and assignments after the management-group hierarchy exists. It is intentionally separate from the governance root so policy promotion, remediation, managed-identity assignment, and deny-mode changes can run through a narrower HCP Terraform workspace.

Use `management_group_ids` from the governance workspace output. Do not configure the same policy definition or assignment in both governance and policy workspaces unless the resource has been deliberately imported and ownership transferred.
