resource "azurerm_nat_gateway" "nat-gateway" {
  name                = var.nat_gateway_name
  location            = var.location
  resource_group_name = var.resource_group_name
  sku_name            = var.sku_name
  #zones               = var.availability_zones


  lifecycle {
    prevent_destroy = false
  }

  tags = var.tags
}

resource "azurerm_public_ip" "pip" {
  count               = var.public_ip_count
  name                = var.public_ip_name
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_nat_gateway_public_ip_association" "associate-pip" {
  count                = var.public_ip_count
  nat_gateway_id       = azurerm_nat_gateway.nat-gateway.id
  public_ip_address_id = azurerm_public_ip.pip[count.index].id
}

resource "azurerm_subnet_nat_gateway_association" "associate-subnet" {
  count          = length(var.subnet_ids)
  subnet_id      = var.subnet_ids[count.index]
  nat_gateway_id = azurerm_nat_gateway.nat-gateway.id
}

