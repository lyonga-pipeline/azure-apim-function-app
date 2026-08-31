locals {
  default_computer_name = substr(replace(replace(replace(var.name, "_", ""), ".", ""), " ", ""), 0, 15)
}
