data "azurerm_client_config" "current" {}

resource "azurerm_resource_group" "spoke" {
  name     = var.spoke
  location = var.location
  tags     = var.tags
}

resource "random_string" "spoke" {
  length  = 10
  special = false
  upper   = false
  lower   = true
  number  = true
}

resource "azurerm_user_assigned_identity" "spoke" {
  resource_group_name = azurerm_resource_group.spoke.name
  location            = azurerm_resource_group.spoke.location
  tags                = azurerm_resource_group.spoke.tags

  name = "${var.spoke}-${random_string.spoke.result}"
}
