provider "azurerm" {
  version             = "~> 2.12.0"
  storage_use_azuread = true

  features {
    key_vault {
      purge_soft_delete_on_destroy = true
    }
  }

  tenant_id       = var.tenant_id
  subscription_id = var.subscription_id
  client_id       = var.client_id
  client_secret   = data.azurerm_key_vault_secret.client_secret.value
  // client_secret   = var.client_secret
}

provider "null" {
  version = "~> 2.1"
}

provider "random" {
  version = "~> 2.2"
}

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
