locals {
  availability_set_name = var.availability_set_name != null ? var.availability_set_name : lower("aset-${format("%s-%s", lower(replace(var.virtual_machine_name, "/[[:^alnum:]]/", "")), var.resource_group_location)}")
}
