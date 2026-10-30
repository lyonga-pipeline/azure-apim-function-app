locals {
  associations = merge({}, [for vm_key, agent in var.agents : {
    for rule_key, id in agent.data_collection_rules : "${vm_key}/${rule_key}" => {
      vm_id  = agent.virtual_machine_id
      dcr_id = id
    }
  }]...)
}
