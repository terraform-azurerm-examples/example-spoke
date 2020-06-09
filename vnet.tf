resource "azurerm_virtual_network" "spoke" {
  name                = var.spoke
  resource_group_name = azurerm_resource_group.spoke.name
  location            = azurerm_resource_group.spoke.location
  tags                = azurerm_resource_group.spoke.tags
  address_space       = var.spoke_vnet_address_space
}

resource "azurerm_subnet" "Web" {
  name                 = "Web"
  resource_group_name  = azurerm_resource_group.spoke.name
  virtual_network_name = azurerm_virtual_network.spoke.name
  address_prefixes     = [cidrsubnet(azurerm_virtual_network.spoke.address_space[0], 1, 0)]
}

resource "azurerm_subnet" "App" {
  name                 = "App"
  resource_group_name  = azurerm_resource_group.spoke.name
  virtual_network_name = azurerm_virtual_network.spoke.name
  address_prefixes     = [cidrsubnet(azurerm_virtual_network.spoke.address_space[0], 1, 1)]
}
