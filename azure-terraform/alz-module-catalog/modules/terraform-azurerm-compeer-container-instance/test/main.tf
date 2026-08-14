module "container_instance" {
  source = "../"

  container_name      = "test-container"
  resource_group_name = "rv-rg"
  location            = "centralindia"
  ip_address_type     = "Private"
  subnet_ids          = ["/subscriptions/145ccdc1-6c51-4e45-a04e-21bdea03d170/resourceGroups/rv-rg/providers/Microsoft.Network/virtualNetworks/rv-network/subnets/container-subnet"]

  container_info = {
    test = {
      name   = "test-container"
      image  = "hashicorp/tfc-agent:latest"
      cpu    = "1"
      memory = "1.5"
      environment_variables = {
        "TFC_AGENT_NAME" : "test"
        "TFC_AGENT_LOG_LEVEL" : "debug"
      }
      secure_environment_variables = {}
      ports = {
        "tcp_80" = {
          port     = 80
          protocol = "TCP"
        }
      }
    }
  }

  dns_config = {
    "dns_config" = {
      nameservers = ["8.8.8.8"]
    }
  }
}