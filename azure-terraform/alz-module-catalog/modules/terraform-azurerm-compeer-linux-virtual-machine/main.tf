/**
* # Linux VM module
*
* This module creates Linux virtual machines along with Disks, Availability set and NIC
*
* # Module Usage
* ```hcl
*   module "linux_vm" {
*      source = "../"
*
*      resource_group_name             = "demo-rg" # FIX-ME Add proper resource group on for testing 
*      virtual_network_name            = "demo-vnet" # FIX-ME Add proper VNet name for testing 
*      subnet_name                     = "linuxvm" # FIX-ME Add proper subnet name for testing
*      virtual_machine_name            = "test-vm"
*      virtual_machine_size            = "Standard_DS2_v2"
*      source_image_id                 = null
*      admin_username                  = "testadmin"
*      disable_password_authentication = true
*      admin_ssh_key_data              = "ssh-rsa <public-key>"
*
*      source_image_reference = {
*         publisher = "Canonical"
*         offer     = "UbuntuServer"
*         sku       = "18.04-LTS"
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