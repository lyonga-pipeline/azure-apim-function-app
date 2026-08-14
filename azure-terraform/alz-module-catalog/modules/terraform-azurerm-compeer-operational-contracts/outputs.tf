output "contracts" {
  value = {
    for key, contract in terraform_data.contract : key => contract.output
  }
}
