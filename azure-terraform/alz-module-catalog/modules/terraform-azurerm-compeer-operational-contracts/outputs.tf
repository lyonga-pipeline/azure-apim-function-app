output "contracts" {
  description = "Map of operational contract keys to their declared attributes, for downstream consumption."
  value = {
    for key, contract in terraform_data.contract : key => contract.output
  }
}

output "manual_control_keys" {
  description = "Contracts that are deliberately NOT Terraform-managed (manual-control / external-system / provider-gap / contract-only)."
  value       = sort([for key, c in var.contracts : key if c.implementation_state != "codified"])
}

output "codified_keys" {
  description = "Contracts that ARE created by Terraform elsewhere and only cross-referenced here."
  value       = sort([for key, c in var.contracts : key if c.implementation_state == "codified"])
}

output "keys_by_state" {
  description = "Contract keys grouped by implementation_state."
  value = {
    for state in ["codified", "manual-control", "external-system", "provider-gap", "contract-only"] :
    state => sort([for key, c in var.contracts : key if c.implementation_state == state])
  }
}
