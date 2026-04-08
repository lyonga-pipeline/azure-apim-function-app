# -----------------------------------------------------------------------------
# Policy Exemption Pattern
# -----------------------------------------------------------------------------
#
# This file is intentionally non-active. All blocks are commented out.
#
# Why exemptions are necessary
# ----------------------------
# The landing-zone-baseline initiative assigns deny policies for public IPs
# and public network access. Some platform resources legitimately need these:
#
#   - Azure Firewall requires a public IP (connectivity stack)
#   - Azure Bastion requires a public IP (connectivity stack)
#   - The diagnostics archive storage account may need AzureServices bypass
#
# These platform resources live under the `platform` management group which
# receives the `platform_foundation` initiative — NOT `landing_zone_baseline` —
# so the deny policies do not apply to them by default. No exemption is needed
# for standard platform resources.
#
# When to create an exemption
# ----------------------------
# 1. A workload in `nonprod` or `prod` has a documented, time-limited need
#    to deviate from a baseline control (e.g. a dev team needs a public IP
#    for a short-lived load test).
# 2. A resource is pre-existing and cannot be migrated immediately — use
#    category "Waiver" with an expiry_date and a linked ticket in description.
# 3. A policy is not applicable to a specific resource type that Terraform
#    cannot express as a policy parameter — use category "MitigationComplete".
#
# Lifecycle
# ---------
# 1. Open a change request. Reference it in the description field.
# 2. Set expiry_date. Azure will stop enforcing the exemption after this date.
# 3. Peer-review and merge through the normal PR gate.
# 4. Remove the exemption resource when the underlying gap is resolved.
# 5. For Waiver category, review and extend before expiry if still needed.
#
# Exemption categories
# --------------------
# "Waiver"             - temporary, the risk is accepted for a limited period
# "MitigationComplete" - control does not apply; alternative control satisfies it
#
# -----------------------------------------------------------------------------
# Example: waiver for a nonprod resource that temporarily requires a public IP
# -----------------------------------------------------------------------------
#
# resource "azurerm_resource_group_policy_exemption" "example_public_ip_waiver" {
#   name                 = "example-public-ip-waiver"
#   resource_group_id    = "/subscriptions/<workload-sub-id>/resourceGroups/<rg-name>"
#   policy_assignment_id = azurerm_management_group_policy_assignment.nonprod.id
#   exemption_category   = "Waiver"
#   display_name         = "Temporary public IP waiver for load-test environment"
#   description          = "TICKET-1234: Load test requires public IP until 2026-06-01. Reviewed by platform team."
#   expires_on           = "2026-06-01T00:00:00Z"
#
#   policy_definition_reference_ids = [
#     "denyPublicIp",
#   ]
# }
#
# -----------------------------------------------------------------------------
# Example: scope an exemption to a single resource rather than a resource group
# -----------------------------------------------------------------------------
#
# resource "azurerm_resource_policy_exemption" "example_storage_public_network_mitigation" {
#   name                 = "example-storage-public-network-mitigation"
#   resource_id          = "<storage-account-resource-id>"
#   policy_assignment_id = azurerm_management_group_policy_assignment.nonprod.id
#   exemption_category   = "MitigationComplete"
#   display_name         = "Storage account uses service endpoint instead of private endpoint"
#   description          = "TICKET-5678: This account uses a VNet service endpoint which satisfies the control. Private endpoint migration scheduled for Q3."
#   expires_on           = "2026-09-30T00:00:00Z"
#
#   policy_definition_reference_ids = [
#     "denyStoragePublicNetwork",
#   ]
# }
