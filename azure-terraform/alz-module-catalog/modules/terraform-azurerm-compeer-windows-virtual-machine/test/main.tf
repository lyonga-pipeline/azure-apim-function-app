provider "azurerm" {
  features {

  }
}

module "windows_vm" {
  source = "../"

  resource_group_name       = "avtest-ncus-np1-rg" # FIX-ME Add proper resource group on for testing 
  subnet_id                 = "proper_subnet"
  virtual_machine_name      = "test-vm"
  virtual_machine_size      = "Standard_DS2_v2"
  source_image_id           = null
  admin_username            = "testadmin"
  admin_password            = "terraformPoc@123"
  enable_automatic_updates  = true
  active_directory_domain   = ""
  active_directory_password = ""
  active_directory_username = ""

  source_image_reference = {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2016-Datacenter"
    version   = "latest"
  }


  data_disks = [
    {
      name                 = "wsvc-disk1"
      disk_size_gb         = 100
      storage_account_type = "Standard_LRS"
      create_option        = "Empty"
      drive_label          = "Logfiles"
      drive_letter         = "Y"
    },
    {
      name                 = "wsvc-disk2"
      disk_size_gb         = 100
      storage_account_type = "Standard_LRS"
      create_option        = "Empty"
      drive_label          = "WebContent"
      drive_letter         = "Z"
    }
  ]
}