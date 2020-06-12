resource "azurerm_key_vault" "spoke" {
  name = substr(replace("${var.spoke}-${random_string.spoke.result}", "/[^0-9A-Za-z\\-]+/", ""), 0, 24) // 3-24 lowercase alnum only

  resource_group_name = azurerm_resource_group.spoke.name
  location            = azurerm_resource_group.spoke.location
  tags                = azurerm_resource_group.spoke.tags
  tenant_id           = var.tenant_id

  sku_name                        = "standard"
  soft_delete_enabled             = true
  enabled_for_deployment          = false
  enabled_for_template_deployment = false
  enabled_for_disk_encryption     = false

}

resource "azurerm_key_vault_access_policy" "service_principal" {
  key_vault_id = azurerm_key_vault.spoke.id

  tenant_id = var.tenant_id
  object_id = data.azurerm_client_config.current.object_id

  certificate_permissions = [
    "Create",
    "Get",
    "Import",
    "List",
    "Update",
    "Delete",
  ]

  key_permissions = [
    "Create",
    "Get",
    "List",
    "Update",
    "Delete",
  ]

  secret_permissions = [
    "Get",
    "List",
    "Set",
    "Delete"
  ]
}

resource "azurerm_key_vault_access_policy" "managed_identity" {
  key_vault_id = azurerm_key_vault.spoke.id

  tenant_id = var.tenant_id
  object_id = azurerm_user_assigned_identity.spoke.principal_id

  certificate_permissions = [
    "Get",
    "List",
  ]

  key_permissions = [
    "Get",
    "List",
  ]

  secret_permissions = [
    "Get",
    "List",
  ]
}

output "key_vault" {
  value = azurerm_key_vault.spoke
}
