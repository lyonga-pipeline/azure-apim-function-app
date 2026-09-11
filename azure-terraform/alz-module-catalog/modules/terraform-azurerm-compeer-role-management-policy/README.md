# terraform-azurerm-compeer-role-management-policy

Manages the PIM **activation policy** for a role at a scope — design doc
Phase 2 Step 6 (require approval, MFA on activation, max activation duration,
notification recipients). Closes what was previously tracked as a
`provider-gap` operational contract in `platform-privileged-access`.

## Contract

`azurerm_role_management_policy` is a singleton per `(scope, role_definition_id)`
— every Azure role at every scope already has an implicit default policy. This
resource **edits the existing policy in place**; it does not create a new
object, and destroying it resets the policy to Azure defaults rather than
deleting anything.

Pair each entry's `role_definition_id` + `scope` with the matching
`terraform-azurerm-compeer-privileged-access` `pim_eligible_role_assignments`
entry so the eligible assignment and its activation rules are configured
together.

## Example

```hcl
policies = {
  platform_admins_owner = {
    role_definition_id = "/providers/Microsoft.Authorization/roleDefinitions/8e3af657-a8ff-443c-a75c-2fe8c4bcb635"
    scope               = "/providers/Microsoft.Management/managementGroups/platform-mg"
    activation_rules = {
      maximum_duration                    = "PT8H"
      require_approval                    = true
      require_justification               = true
      require_multifactor_authentication  = true
      approvers = [
        { object_id = "<AZ-SEC-Admins group object id>", type = "Group" }
      ]
    }
    notification_rules = {
      eligible_activations = {
        admin_notifications = { default_recipients = true, notification_level = "All" }
      }
    }
  }
}
```

## Tests

`terraform test` (offline, `mock_provider`): empty plan, activation rules with
an approval stage, active/eligible assignment rules, and notification rules
across all three rule sets.
