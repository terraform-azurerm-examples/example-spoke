resource "azurerm_storage_account" "boot_diagnostics" {
  name                = substr(replace(lower("${var.spoke}-${random_string.spoke.result}"), "/[^0-9a-z]+/", ""), 0, 24) // 3-24 lowercase alnum only
  resource_group_name = azurerm_resource_group.spoke.name
  location            = azurerm_resource_group.spoke.location
  tags                = azurerm_resource_group.spoke.tags

  account_kind             = "StorageV2"
  account_tier             = "Standard"
  account_replication_type = "LRS"
}


output "boot_diagnostics" {
  value = azurerm_storage_account.boot_diagnostics
}
