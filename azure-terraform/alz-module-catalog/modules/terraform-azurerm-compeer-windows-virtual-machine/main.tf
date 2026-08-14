/**
* # Windows VM module
*
* This module creates windows virtual machines along with Disks, Availability set and NIC
*
* # Module Usage
* ```hcl
*   module "windows_vm" {
*      source = "../"
*
*      resource_group_name      = "demo-rg" # FIX-ME Add proper resource group on for testing 
*      virtual_network_name     = "demo-vnet" # FIX-ME Add proper VNet name for testing 
*      subnet_name              = "windowsvm" # FIX-ME Add proper subnet name for testing
*      virtual_machine_name     = "test-vm"
*      virtual_machine_size     = "Standard_DS2_v2"
*      source_image_id          = null
*      admin_username           = "testadmin"
*      enable_automatic_updates = true
*
*      source_image_reference = {
*         publisher = "MicrosoftWindowsServer"
*         offer     = "WindowsServer"
*         sku       = "2016-Datacenter"
*         version   = "latest"
*      }
*
*
*      data_disks = [
*         {
*            name                 = "disk1"
*            disk_size_gb         = 100
*            storage_account_type = "StandardSSD_LRS"
*            create_option        = "Empty"
*            drive_letter         = "Y"
*            drive_label          = "logging"
*         },
*         {
*            name                 = "disk2"
*            disk_size_gb         = 200
*            storage_account_type = "Standard_LRS"
*            create_option        = "Empty"
*         }
*      ]
*   }
* ```
*  `*Note:* Active directory details were not passed on to the above module usage example.`
*/