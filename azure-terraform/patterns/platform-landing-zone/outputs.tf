output "component_coverage" {
  value = terraform_data.coverage_contract.output
}

output "blocking_components" {
  value = {
    for id, component in local.component_coverage : id => component
    if component.criticality == "Blocking"
  }
}

output "critical_components" {
  value = {
    for id, component in local.component_coverage : id => component
    if component.criticality == "Critical"
  }
}

output "contract_only_components" {
  value = {
    for id, component in local.component_coverage : id => component
    if contains(["contract", "external-governed", "cost-disabled", "module-only", "not-composed", "documentation"], component.status)
  }
}

output "phase2_components" {
  value = local.phase2_components
}

output "deferred_components" {
  value = {
    for id, component in local.component_coverage : id => component
    if component.phase == "Phase 2" || component.criticality == "Deferred"
  }
}

output "implementation_summary" {
  value = local.implementation_summary
}
