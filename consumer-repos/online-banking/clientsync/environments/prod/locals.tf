locals {
  function_app = merge(var.function_app, {
    infrastructure_app_settings = merge(
      {
        COMPEER_APPLICATION = var.application.code
        COMPEER_ENVIRONMENT = var.environment
      },
      try(var.function_app.infrastructure_app_settings, {}),
    )
  })

  key_vault = merge(var.key_vault, {
    secrets = var.key_vault_secrets
  })
}
