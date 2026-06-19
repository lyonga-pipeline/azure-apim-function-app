# Platform Connectivity Root

This root creates shared network foundations for a landing-zone environment.

It keeps address allocation explicit in the root input contract. The VNet module receives VNet address spaces and typed subnet maps, then outputs `subnet_ids` keyed by the same subnet purpose keys.

NSGs, route tables, Private DNS zones, and VNet links are composed outside the VNet base module so networking ownership remains visible.

