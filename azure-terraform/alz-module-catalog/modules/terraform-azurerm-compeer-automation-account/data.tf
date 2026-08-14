data "local_file" "runbook_content" {
  for_each = var.runbook_configuration
  filename = "${path.root}/${each.value.runbook_content_filename}"
}