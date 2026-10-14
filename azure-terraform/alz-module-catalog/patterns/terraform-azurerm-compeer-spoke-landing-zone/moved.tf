moved {
  from = module.hub_to_spoke[0]
  to   = module.peering[0].module.hub_to_spoke_peering
}

moved {
  from = module.spoke_to_hub[0]
  to   = module.peering[0].module.spoke_to_hub_peering
}
