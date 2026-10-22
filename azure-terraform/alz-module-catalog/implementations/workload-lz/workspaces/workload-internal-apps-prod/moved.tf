# Preserve addresses from the former shared adapter in this SAME state.
# These moves do not transfer resources between workspaces or subscriptions.
moved {
  from = module.deployment.module.blueprint
  to   = module.blueprint
}

moved {
  from = module.deployment.time_static.deployment_created
  to   = time_static.deployment_created
}

moved {
  from = module.deployment.terraform_data.deployment_contract
  to   = terraform_data.deployment_contract
}
