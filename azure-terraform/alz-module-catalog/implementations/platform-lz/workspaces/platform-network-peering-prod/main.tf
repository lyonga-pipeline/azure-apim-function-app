# NEW: environment/hub attachment state. Existing single-pair roots and VNet owners are unchanged.
locals {
  environment = "prod"
}
resource "terraform_data" "adoption_contract" {
  input = var.enabled
  lifecycle {
    precondition {
      condition = var.enabled ? (
        var.hub != null && var.deployment_controls.exclusive_ownership_verified &&
        var.deployment_controls.shared_hub_gate_configured &&
        length(trimspace(var.deployment_controls.approval_reference)) > 0 &&
        (var.tfc_azure_dynamic_credentials != null || var.allow_local_cli_auth)
      ) : length(var.attachments) == 0
      error_message = "Enabling requires an approved hub, ownership handoff, shared-hub gate, approval reference and OIDC (or explicit local auth). Disabled roots must have empty inventories."
    }
  }
}
module "attachments" {
  source                  = "../../../../patterns/terraform-azapi-compeer-network-attachments"
  count                   = var.enabled ? 1 : 0
  tenant_id               = var.tenant_id
  environment             = local.environment
  hub                     = var.hub
  attachments             = var.attachments
  reserved_address_spaces = var.reserved_address_spaces
  depends_on              = [terraform_data.adoption_contract]
}
