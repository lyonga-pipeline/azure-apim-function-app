locals {
  terraform_validation_pipeline = <<-YAML
trigger:
- main

name: $(date:yyyyMMdd)$(rev:.r)

variables:
- group: IAC_Library
- name: vmPoolImage
  value: 'ubuntu-latest'

resources:
  repositories:
    - repository: corePipelines
      type: git
      name: ${var.core_pipelines_repository}
      ref: ${var.core_pipelines_ref}

stages:
- stage: SecurityAndQuality
  displayName: Security & Terraform checks
  jobs:
  - job: OrcaScan
    displayName: Orca IaC Security scan
    pool:
      vmImage: $(vmPoolImage)
    steps:
      - template: templates/Orca_IAC_scan_template.yml@corePipelines
        parameters:
          ORCA_SECURITY_API_TOKEN: '$(ORCA_SECURITY_API_TOKEN)'

  - template: templates/terraform-iac-scan.yml@corePipelines
    parameters:
      targetRepo: self
      workingDirectory: '.'
      terraformVersion: '${var.terraform_version}'
      tflintVersion: '${var.tflint_version}'
      continueOnError: true
      vmImage: $(vmPoolImage)
YAML

  opa_validation_pipeline = <<-YAML
trigger:
- main

name: $(date:yyyyMMdd)$(rev:.r)

pool:
  vmImage: ubuntu-latest

steps:
- checkout: self
  clean: true

- bash: |
    set -euo pipefail
    OPA_VERSION="1.8.0"
    curl -fsSL -o opa "https://openpolicyagent.org/downloads/v$${OPA_VERSION}/opa_linux_amd64_static"
    chmod +x opa
    ./opa fmt --fail --diff policies
    ./opa test policies -v
  displayName: Validate OPA policies
YAML

  terraform_repo_readme = <<-MD
# Azure Landing Zone Platform IaC

This repository contains Terraform configuration for the new platform Azure Landing Zone.

## Workspace roots

Each long-lived HCP Terraform workspace points to one directory under `platform/` and to the `main` branch. Environment branches are intentionally not used for platform domains.

Terraform execution is authoritative in HCP Terraform. Azure DevOps performs pull-request / commit validation only.
MD

  opa_repo_readme = <<-MD
# Azure Landing Zone Policy as Code

This repository contains OPA/Rego policy sets used by HCP Terraform for the new platform Landing Zone.

Policies start as advisory. Promote individual policies to mandatory only after representative ALZ plans are tested.
MD

  domain_versions = <<-HCL
terraform {
  required_version = ">= ${var.terraform_version}, < 2.0.0"
}
HCL

  starter_policies_hcl = <<-HCL
policy "alz_baseline" {
  query             = "data.terraform.alz.baseline.deny"
  enforcement_level = "advisory"
  description       = "Starter ALZ policy. Replace or extend with approved enterprise controls."
}
HCL

  starter_rego = <<-REGO
package terraform.alz.baseline

# Starter policy intentionally passes. Replace/extend with tested ALZ controls.
deny := []
REGO

  starter_rego_test = <<-REGO
package terraform.alz.baseline

test_baseline_passes if {
  count(deny) == 0
}
REGO

  repository_files = {
    for repo_key, repo in var.repositories : repo_key => merge(
      repo.repository_type == "terraform" ? {
        "IAC-Build-Validation.yml" = local.terraform_validation_pipeline
        ".gitignore" = <<-TXT
.terraform/
*.tfstate
*.tfstate.*
*.tfplan
crash.log
*.auto.tfvars
*.auto.tfvars.json
TXT
        "README.md" = local.terraform_repo_readme
      } : {
        "IAC-Build-Validation.yml" = local.opa_validation_pipeline
        ".gitignore"               = ".opa/\n"
        "README.md"                = local.opa_repo_readme
        "policies.hcl"             = local.starter_policies_hcl
        "policies/alz_baseline.rego"      = local.starter_rego
        "policies/alz_baseline_test.rego" = local.starter_rego_test
      },
      repo.repository_type == "terraform" ? {
        for dir in repo.seed_directories : "${trimsuffix(dir, "/")}/versions.tf" => local.domain_versions
      } : {}
    )
  }
}
