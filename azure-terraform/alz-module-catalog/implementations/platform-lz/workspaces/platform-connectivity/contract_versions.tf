# Platform_Output_Contracts_IAC-10: fail the plan loudly if a producer
# workspace's published contract_version has drifted from what this
# workspace was built and tested against, instead of silently falling back
# to a default via try() when a field this workspace reads is renamed or
# removed upstream. Bump the literal expected version below only after
# confirming every field this workspace reads from that producer is still
# compatible - see the producer's outputs.tf for what changed.
resource "terraform_data" "contract_versions" {
  input = {
    management_contract_version = try(local.management_outputs.contract_version, null)
  }

  lifecycle {
    precondition {
      condition     = try(local.management_outputs.contract_version, null) == null || try(local.management_outputs.contract_version, null) == "0.1.0"
      error_message = "platform-management's published contract_version has changed - review its outputs.tf for breaking changes before updating the expected version in this file."
    }
  }
}
