
resource "azurerm_virtual_network_peering" "spoke_to_hub" {
  name                      = "${azurerm_virtual_network.spoke.name}_to_${data.terraform_remote_state.hub.outputs.vnet.resource_group_name}"
  resource_group_name       = azurerm_virtual_network.spoke.resource_group_name
  virtual_network_name      = azurerm_virtual_network.spoke.name
  remote_virtual_network_id = data.terraform_remote_state.hub.outputs.vnet.id

  allow_virtual_network_access = true
  allow_forwarded_traffic      = false
  allow_gateway_transit        = false
  use_remote_gateways          = true
}

resource "azurerm_virtual_network_peering" "hub_to_spoke" {
  name                      = "${data.terraform_remote_state.hub.outputs.vnet.resource_group_name}_to_${azurerm_virtual_network.spoke.name}"
  resource_group_name       = data.terraform_remote_state.hub.outputs.vnet.resource_group_name
  virtual_network_name      = data.terraform_remote_state.hub.outputs.vnet.name
  remote_virtual_network_id = azurerm_virtual_network.spoke.id

  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = true
  use_remote_gateways          = false
}