resource "azurerm_application_security_group" "appgw_pool" {
  for_each            = toset(var.application_gateway_pools)
  name                = each.value
  resource_group_name = azurerm_resource_group.web.name
  location            = azurerm_resource_group.web.location
  tags                = azurerm_resource_group.web.tags
}
