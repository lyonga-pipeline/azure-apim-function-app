provider "azurerm" {
  features {

  }
}


data "azurerm_subnet" "subnet" {
  name                 = "sb1-vm-general-subnet"
  virtual_network_name = "ncus-sb1-10.100.56.0-vnet"
  resource_group_name  = "net-ncus-sb1-rg"
}

module "linux_vm" {
  source = "../"

  resource_group_name             = "net-ncus-sb1-rg" # FIX-ME Add proper resource group on for testing 
  subnet_id                       = data.azurerm_subnet.subnet.id
  virtual_machine_name            = "test-vm"
  virtual_machine_size            = "Standard_DS1_v2"
  source_image_id                 = null
  admin_username                  = "testadmin"
  disable_password_authentication = true
  admin_ssh_key_data              = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDWzsmly6hy06CVU+5rEORV4B1S+6zduBfV3C0nWW0tYj7TktdNAoUhmW4QST1OYgqkqTOnvN7IQ0qrqDJSo8VgHqo4R0N5Vu5W0OoE41I9cGuvtBo2wNjl86lzkMdY8D+/Np7c1jycqH2B88CTGadYGoHEkV4DoC4HB2g5kpjMrmw5j7CV3ExzS2L0PEY5XEPxKbx1r5g4DzH8QQl9q7dmtW9WWm7IGmL0E+l7dK8rXK5z8j1tcg6TB2jlwmju3j0zxqUAmwQ7b7w9t+1eG6IpVv8OyQ4ruY+qJmFAIOB0gG2qY8F8fSE5A4C+dPr+kUe0UKe7o0fI79R+1d6me5lB4C6L4P9go6uWLa8g9o0X9Tn9N0zz8Qi0ou24Qg3M8ry3x5zYFXvH71g8mBe9NbpA4KjGxEV6xDY7uQdb6uv0LGC7xQ8oOm0Fjz0IbxqCv1Z6SV8SxNltq8FChMlAiqP8s3c5U4B8ytm0O5l8pFQzF9Ik/LV8/X4Jv6xV6d2qH8BNxD5ttJ05WklvVdPC8f7LQf23RQ3M7h2Pj2q8hdYHOmQ2h2uD8xAwfSe52Lh+aujlwmR1D9MEsb5NEh53Uxt0Qgr0R5yfi9YjTt8M1mM+3CeuujPVvhg3p+c0PgSYkJzMi6wwDUm+5uO60c3lD27A+XCFECk76Q== test@example"
  active_directory_domain         = ""
  active_directory_password       = ""
  active_directory_username       = ""

  source_image_reference = {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }


  data_disks = [
    {
      name                 = "disk1"
      disk_size_gb         = 100
      storage_account_type = "StandardSSD_LRS"
      create_option        = "Empty"
    },
    {
      name                 = "disk2"
      disk_size_gb         = 200
      storage_account_type = "Standard_LRS"
      create_option        = "Empty"
    }
  ]
}