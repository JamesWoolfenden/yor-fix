
resource "azurerm_subnet" "subnet" {
  name                                           = "${var.app_name}-${var.environment}-subnet"
  resource_group_name                            = "inf-${var.environment}"
  virtual_network_name                           = var.east_vnet_name
  address_prefixes                               = ["${var.subnet_address_prefix}"]
  enforce_private_link_endpoint_network_policies = true

  delegation {
    name = "Microsoft.Web.serverFarms"

    service_delegation {
      name    = "Microsoft.Web/serverFarms"
      actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
    }
  }
}

resource "azurerm_public_ip" "outbound" {
  name                = "${var.app_name}-${var.environment}-pip"
  location            = azurerm_resource_group.infrastructure.location
  resource_group_name = azurerm_resource_group.infrastructure.name
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = ["1", "2", "3"]
  tags = {
    environment = "${var.environment}"
    modifiedBy  = "terraform"
  }
}

resource "azurerm_nat_gateway" "nat" {
  name                = "${var.app_name}-${var.environment}-nat"
  location            = azurerm_resource_group.infrastructure.location
  resource_group_name = azurerm_resource_group.infrastructure.name
  tags = {
    environment = "${var.environment}"
    modifiedBy  = "terraform"
  }
}

resource "azurerm_nat_gateway_public_ip_association" "nat_gateway" {
  nat_gateway_id       = azurerm_nat_gateway.nat.id
  public_ip_address_id = azurerm_public_ip.outbound.id
}

resource "azurerm_subnet_nat_gateway_association" "natsubnet" {
  subnet_id      = azurerm_subnet.subnet.id
  nat_gateway_id = azurerm_nat_gateway.nat.id
}

resource "azurerm_app_service_virtual_network_swift_connection" "api" {
  app_service_id = azurerm_windows_web_app.api.id
  subnet_id      = azurerm_subnet.subnet.id
}
