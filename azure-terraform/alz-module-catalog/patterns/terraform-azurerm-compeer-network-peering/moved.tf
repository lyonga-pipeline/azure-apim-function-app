moved {
  from = module.hub_to_spoke_peering
  to   = module.attachment.module.hub_to_spoke_peering
}
moved {
  from = module.spoke_to_hub_peering
  to   = module.attachment.module.spoke_to_hub_peering
}
moved {
  from = module.private_dns_spoke_links
  to   = module.attachment.module.private_dns_spoke_links
}
