resource "azurerm_resource_group" "web" {
  name     = "${var.spoke}-web"
  location = var.location
  tags     = var.tags
}

locals {
  web_set_defaults = {
    resource_group_name = azurerm_resource_group.web.name
    location            = azurerm_resource_group.web.location
    tags                = azurerm_resource_group.web.tags
    availability_set    = true
    load_balancer       = false
    subnet_id           = azurerm_subnet.Web.id
  }

  web_vm_defaults = {
    resource_group_name  = azurerm_resource_group.web.name
    location             = azurerm_resource_group.web.location
    tags                 = azurerm_resource_group.web.tags
    admin_username       = "ubuntu"
    admin_ssh_public_key = azurerm_key_vault_secret.ssh_pub_key["ubuntu"].value
    additional_ssh_keys  = []
    vm_size              = "Standard_B1ls"
    storage_account_type = "Standard_LRS"
    subnet_id            = azurerm_subnet.Web.id
    boot_diagnostics_uri = azurerm_storage_account.boot_diagnostics.primary_blob_endpoint
  }
}

/*
module "athenawebhelp_set" {
  source            = "github.com/terraform-azurerm-modules/terraform-azurerm-set" #?ref=v0.1"
  defaults          = local.web_set_defaults
  module_depends_on = [local.application_gateway_backend_pool_ids]

  name                                = "athenawebhelp"
  application_gateway_backend_pool_id = local.application_gateway_backend_pool_ids["athenawebhelp"]
}

module "athenawebhelp_vms" {
  // source            = "github.com/terraform-azurerm-modules/terraform-azurerm-linux-vm" #?ref=v0.1"
  source            = "github.com/terraform-azurerm-modules/terraform-azurerm-linux-vm" #?ref=v0.1"
  defaults          = local.web_vm_defaults
  module_depends_on = [module.athenawebhelp_set]

  attachType = "ApplicationGateway"
  attach     = module.athenawebhelp.set_ids

  names           = ["athenawebhelp-a", "athenawebhelp-b", "athenawebhelp-c"]
  source_image_id = data.azurerm_image.ubuntu_18_04.id
}

resource "azurerm_application_security_group" "web_pool2" {
  name                = "web-pool2"
  resource_group_name = azurerm_resource_group.web.name
  location            = azurerm_resource_group.web.location
  tags                = azurerm_resource_group.web.tags
}
*/

resource "azurerm_linux_virtual_machine_scale_set" "athenawebhelp" {
  name                = "athenawebhelp"
  resource_group_name = azurerm_resource_group.web.name
  location            = azurerm_resource_group.web.location
  tags                = azurerm_resource_group.web.tags
  depends_on          = [local.application_gateway_backend_pool_ids]


  sku                          = "Standard_B1ls"
  instances                    = 2
  proximity_placement_group_id = null
  // zones                        = ["1", "2", "3"]

  lifecycle {
    ignore_changes = [
      instances,
    ]
  }

  admin_username = "ubuntu"

  admin_ssh_key {
    username   = "ubuntu"
    public_key = azurerm_key_vault_secret.ssh_pub_key["ubuntu"].value
  }

  source_image_id = data.azurerm_image.ubuntu_18_04.id


  os_disk {
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
  }

  network_interface {
    name                          = "athenawebhelp-nic"
    primary                       = true
    enable_accelerated_networking = false
    network_security_group_id     = null

    ip_configuration {
      name      = "internal"
      primary   = true
      subnet_id = azurerm_subnet.Web.id

      application_gateway_backend_address_pool_ids = [local.application_gateway_backend_pool_ids["athenawebhelp"]]
      application_security_group_ids               = [azurerm_application_security_group.appgw_pool["athenawebhelp"].id]
    }
  }

  boot_diagnostics {
    storage_account_uri = azurerm_storage_account.boot_diagnostics.primary_blob_endpoint
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.spoke.id]
  }
}

/*
resource "azurerm_application_security_group" "web_pool3" {
  name                = "web-pool3"
  resource_group_name = azurerm_resource_group.web.name
  location            = azurerm_resource_group.web.location
  tags                = azurerm_resource_group.web.tags
}

/*
resource "azurerm_linux_virtual_machine_scale_set" "web_pool3" {
  name                = "web-pool3"
  resource_group_name = azurerm_resource_group.web.name
  location            = azurerm_resource_group.web.location
  tags                = azurerm_resource_group.web.tags
  depends_on          = [local.application_gateway_backend_pool_ids]


  sku                          = "Standard_B1ls"
  instances                    = 3
  proximity_placement_group_id = null
  // zones                        = ["1", "2", "3"]

  lifecycle {
    ignore_changes = [
      instances,
    ]
  }

  admin_username = "ubuntu"

  admin_ssh_key {
    username   = "ubuntu"
    public_key = azurerm_key_vault_secret.ssh_pub_key["ubuntu"].value
  }

  source_image_id = data.azurerm_image.ubuntu_18_04.id


  os_disk {
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
  }

  network_interface {
    name                          = "web-pool3-nic"
    primary                       = true
    enable_accelerated_networking = false
    network_security_group_id     = null

    ip_configuration {
      name      = "internal"
      primary   = true
      subnet_id = azurerm_subnet.Web.id

      application_gateway_backend_address_pool_ids = []
      application_security_group_ids               = [azurerm_application_security_group.web_pool3.id]
    }
  }


  // upgrade_mode = "Manual"
  //
  // health_probe_id = local.application_gateway_probe_id["Https"]
  //
  // automatic_instance_repair {
  //   enabled = true
  // }

  boot_diagnostics {
    storage_account_uri = azurerm_storage_account.boot_diagnostics.primary_blob_endpoint
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.spoke.id]
  }
}

resource "azurerm_monitor_autoscale_setting" "pool3" {
  name                = "autoscale-config"
  resource_group_name = azurerm_resource_group.web.name
  location            = azurerm_resource_group.web.location
  target_resource_id  = azurerm_linux_virtual_machine_scale_set.web_pool3.id
  depends_on          = [azurerm_linux_virtual_machine_scale_set.web_pool3]

  profile {
    name = "AutoScale"

    capacity {
      default = 2
      minimum = 1
      maximum = 6
    }

    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_resource_id = azurerm_linux_virtual_machine_scale_set.web_pool3.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "GreaterThan"
        threshold          = 75
      }

      scale_action {
        direction = "Increase"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT1M"
      }
    }

    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_resource_id = azurerm_linux_virtual_machine_scale_set.web_pool3.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "LessThan"
        threshold          = 25
      }

      scale_action {
        direction = "Decrease"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT1M"
      }
    }
  }

  // notification {
  //   email {
  //     send_to_subscription_administrator    = true
  //     send_to_subscription_co_administrator = true
  //     custom_emails                         = ["admin@contoso.com"]
  //   }
  // }
}
*/