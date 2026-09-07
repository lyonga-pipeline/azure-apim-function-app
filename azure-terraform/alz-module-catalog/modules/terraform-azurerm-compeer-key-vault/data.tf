# The vault is always bound to the deploying identity's tenant unless the
# caller overrides `tenant_id` explicitly (cross-tenant is rare).
data "azurerm_client_config" "current" {}
