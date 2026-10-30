# Generic VNet Attachment Producer

Provider-free, output-only adapter for **any approved existing platform or workload VNet owner**. It creates no VNet, peering, DNS link, RBAC grant or state handoff. The consumer independently verifies Git approval, the producer contract and actual Azure CIDRs.

Pass actual outputs from the existing VNet module into `virtual_network={id,address_space}`, plus `tenant_id`, the real `environment`, `hub_virtual_network_id` and `attachment_kind` (`platform` by default; explicitly set `workload` for applications). Optional `gateway_transit=false` is requested intent only; `private_dns_zone_ids={}` contains only existing approved central zones. DNS auto-registration is always off.

The output `network_attachment_contract` v3.0.0 contains owner, VNet/hub IDs, address spaces, tenant/subscription/environment/classification context and exact DNS intent. Publish it from the VNet's existing root:

```hcl
module "attachment_contract" {
  source                 = "../../../../patterns/terraform-azapi-compeer-network-attachments/producer"
  tenant_id              = var.tenant_id
  environment            = var.environment
  attachment_kind        = "platform"
  hub_virtual_network_id = local.connectivity_outputs.hub_virtual_network_id
  virtual_network = {
    id            = module.platform_vnet.id
    address_space = module.platform_vnet.address_space
  }
}
output "network_attachment_contract" {
  value = module.attachment_contract.network_attachment_contract
}
```

Replace `module.platform_vnet` with the actual producer's output references; this is not a request to create another VNet. The relative source is development composition; package/pin the producer submodule before deployment. See the [extended example](../examples/platform-producer.tf.example). The attachment inventory sets `producer.contract_version="3.0.0"` and the matching `attachment_kind`; it omits `naming_context` because peering/link names derive from the existing VNet names.

Do not add this adapter to a consumer as a way to self-approve arbitrary VNet IDs. The authorized VNet owner publishes it, the network team approves independent inventory, and output readers use only non-sensitive HCP outputs. Existing workload-v2 consumers/producers remain compatible. Existing identity or other platform peering resources stay at their current addresses until an approved, non-destructive ownership handoff is completed.
