resource "azurerm_virtual_network" "spoke" {
  name                = var.spoke
  resource_group_name = azurerm_resource_group.spoke.name
  location            = azurerm_resource_group.spoke.location
  tags                = azurerm_resource_group.spoke.tags
  address_space       = var.spoke_vnet_address_space
}

resource "azurerm_subnet" "Web" {
  depends_on           = [azurerm_virtual_network.spoke]
  name                 = "Web" // .0/26
  resource_group_name  = azurerm_resource_group.spoke.name
  virtual_network_name = azurerm_virtual_network.spoke.name
  address_prefixes     = [cidrsubnet(azurerm_virtual_network.spoke.address_space[0], 2, 0)]

  service_endpoints = ["Microsoft.KeyVault"]

}

resource "azurerm_subnet" "App" {
  depends_on           = [azurerm_subnet.Web]
  name                 = "App" // .128/26
  resource_group_name  = azurerm_resource_group.spoke.name
  virtual_network_name = azurerm_virtual_network.spoke.name
  address_prefixes     = [cidrsubnet(azurerm_virtual_network.spoke.address_space[0], 2, 2)]

  service_endpoints = ["Microsoft.Sql", "Microsoft.KeyVault"]

}

resource "azurerm_subnet" "AppGw" {
  depends_on           = [azurerm_subnet.App]
  name                 = "AppGw" // .240/28
  resource_group_name  = azurerm_resource_group.spoke.name
  virtual_network_name = azurerm_virtual_network.spoke.name
  address_prefixes     = [cidrsubnet(azurerm_virtual_network.spoke.address_space[0], 4, 15)]

  service_endpoints = ["Microsoft.KeyVault"]
}

output "vnet" {
  value = azurerm_virtual_network.spoke
}