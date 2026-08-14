variable "resource_group_name" {
  description = "The name of the resource group"
  type        = string
}

variable "location" {
  description = "The location/region to keep all your network resources.'"
}

variable "storage_account_id" {
  description = "The ID of the storage account"
  type        = string
}

variable "data_lake_gen2_fs_name" {
  description = "The name of the gen2 file system"
  type        = string
}