resource "random_password" "passwd" {
  count       = var.admin_password == null ? 1 : 0
  length      = var.random_password_length
  min_upper   = 4
  min_lower   = 2
  min_numeric = 4
  special     = false

  keepers = {
    admin_password = var.virtual_machine_name
  }
}
