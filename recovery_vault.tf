resource "azurerm_recovery_services_vault" "spoke" {
  name                = "${var.spoke}-recovery-vault"
  resource_group_name = azurerm_resource_group.spoke.name
  location            = azurerm_resource_group.spoke.location
  tags                = azurerm_resource_group.spoke.tags

  sku                 = "Standard"
  soft_delete_enabled = true
}

resource "azurerm_backup_policy_vm" "default" {
  name                = "default"
  resource_group_name = azurerm_resource_group.spoke.name
  recovery_vault_name = azurerm_recovery_services_vault.spoke.name

  timezone = "UTC"

  backup {
    frequency = "Daily"
    time      = "23:00"
  }

  retention_daily {
    count = 14 //Between 1 & 9999
  }

  retention_weekly {
    count    = 13
    weekdays = ["Wednesday", "Sunday"]
  }

  retention_monthly {
    count    = 12
    weekdays = ["Sunday"]
    weeks    = ["Last"]
  }

  retention_yearly {
    count    = 3
    weekdays = ["Sunday"]
    weeks    = ["Last"]
    months   = ["January"]
  }
}

output "recovery_services_vault" {
  value = azurerm_recovery_services_vault.spoke
}

output "default_vm_backup_policy" {
  value = azurerm_backup_policy_vm.default
}
