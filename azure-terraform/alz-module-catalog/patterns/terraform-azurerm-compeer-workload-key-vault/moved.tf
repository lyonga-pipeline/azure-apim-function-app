moved {
  from = module.diagnostics
  to   = module.diagnostics[0]
}

# Preserve the existing single endpoint when upgrading to the keyed interface.
moved {
  from = module.private_endpoint
  to   = module.private_endpoint["default"]
}
