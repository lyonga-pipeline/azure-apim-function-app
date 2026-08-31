module "automation" {
  source                  = "../"
  automation_account_name = "test-automation"
  resource_group_name     = "test-openai"

  #   runbook_configuration = {
  #     "script1" = {
  #       runbook_name             = "automation-runbook"
  #       runbook_content_filename = "scripts/powershell.ps1"
  #       runbook_type             = "PowerShell72"
  #       runbook_log_verbose      = "false"
  #       runbook_log_progress     = "false"
  #     },
  #     "script2" = {
  #       runbook_name             = "automation-runbook-2"
  #       runbook_content_filename = "scripts/powershell.ps1"
  #       runbook_type             = "PowerShell72"
  #       runbook_log_verbose      = "false"
  #       runbook_log_progress     = "false"
  #     }
  #   }
  #   runbook_name             = "automation-runbook"
  #   runbook_content_filename = "./scripts/powershell.ps1"
  # runbook_content = data.local_file.runbook_content.content
}