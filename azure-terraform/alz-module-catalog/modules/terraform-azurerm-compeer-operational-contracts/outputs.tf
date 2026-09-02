output "contracts" {
  description = "Map of operational contract keys to their declared attributes, for downstream consumption."
  value = {
    for key, contract in terraform_data.contract : key => contract.output
  }
}
