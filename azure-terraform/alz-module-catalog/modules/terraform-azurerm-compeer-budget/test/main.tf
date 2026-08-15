module "budget" {
  source = "../"

  resource_group_name         = "test-openai"
  rg_budget_name              = "test-budget"
  rg_amount                   = 100
  budget_start_date           = "2024-02-01T00:00:00Z"
  notification_contact_emails = ["bsivaku@compeer.com"]
}