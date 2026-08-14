locals {
  nic_name              = var.nic_name != null ? var.nic_name : lower("nic-${format("%s", lower(replace(var.virtual_machine_name, "/[[:^alnum:]]/", "")))}")
  ipconfig_name         = var.ip_configuration_name != null ? var.ip_configuration_name : lower("ipconfig-${format("%s", lower(replace(var.virtual_machine_name, "/[[:^alnum:]]/", "")))}")
  admin_password        = var.admin_password == null ? element(concat(random_password.passwd.*.result, [""]), 0) : var.admin_password
  availability_set_name = var.availability_set_name != null ? var.availability_set_name : lower("aset-${format("%s-%s", lower(replace(var.virtual_machine_name, "/[[:^alnum:]]/", "")), var.resource_group_location)}")
  vm_data_disks = { for index, data_disk in var.data_disks : data_disk.name => {
    index : index,
    data_disk : data_disk,
    }
  }

  drive_letter = join(",", [for data_disk in var.data_disks : "\"${data_disk.drive_letter == null ? "" : data_disk.drive_letter}\""])
  drive_label  = join(",", [for data_disk in var.data_disks : "\"${data_disk.drive_label == null ? "" : data_disk.drive_label}\""])

}