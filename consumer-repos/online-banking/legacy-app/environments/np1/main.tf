module "legacy_app" {
  source = "../../modules/legacy-function-app"

  location    = var.location
  environment = var.environment
  settings    = var.legacy_app
}
