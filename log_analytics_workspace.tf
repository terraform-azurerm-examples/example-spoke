resource "azurerm_log_analytics_workspace" "spoke" {
  name                = substr(replace("${var.spoke}-${random_string.spoke.result}", "/[^0-9A-Za-z\\-]+/", ""), 0, 24) // 3-24 lowercase alnum only
  resource_group_name = azurerm_resource_group.spoke.name
  location            = azurerm_resource_group.spoke.location
  tags                = azurerm_resource_group.spoke.tags

  sku               = "PerGB2018"
  retention_in_days = 30 // Max 730
}

output "log_analytics_workspace" {
  value = azurerm_log_analytics_workspace.spoke
}