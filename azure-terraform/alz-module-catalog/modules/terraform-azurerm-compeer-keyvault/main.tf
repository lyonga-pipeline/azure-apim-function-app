locals {
  # Merge the list and keyed access-policy inputs into one keyed map with stable
  # keys. List entries are keyed by object_id (+ application_id) so re-ordering
  # the list never churns policies.
  access_policies = merge(
    {
      for p in var.access_policies :
      join("|", compact([p.tenant_id, p.object_id, try(p.application_id, "")])) => p
    },
    var.access_policies_by_key,
  )
}
