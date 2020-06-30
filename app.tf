resource "azurerm_resource_group" "spoke_app" {
  name     = "${var.spoke}-app-vms"
  location = var.location
  tags     = var.tags
}

locals {
  app_vm_defaults = {
    resource_group_name  = azurerm_resource_group.spoke_app.name
    location             = azurerm_resource_group.spoke_app.location
    tags                 = azurerm_resource_group.spoke_app.tags
    admin_username       = "ubuntu"
    admin_ssh_public_key = azurerm_key_vault_secret.ssh_pub_key["ubuntu"].value
    additional_ssh_keys  = []
    vm_size              = "Standard_B1ls"
    storage_account_type = "Standard_LRS"
    identity_id          = azurerm_user_assigned_identity.spoke.id
    subnet_id            = azurerm_subnet.app.id
    boot_diagnostics_uri = azurerm_storage_account.boot_diagnostics.primary_blob_endpoint
  }
}


resource "azurerm_application_security_group" "app" {
  for_each            = toset(["app"])
  name                = each.value
  resource_group_name = azurerm_resource_group.spoke_app.name
  location            = azurerm_resource_group.spoke_app.location
  tags                = azurerm_resource_group.spoke_app.tags
}

locals {
  application_security_groups = {
    // include web ASGs? Move ASGs to the NSG,tf?
    for object in azurerm_application_security_group.app :
    object.name => {
      name = object.name
      id   = object.id
    }
  }
}

//======================================================

module "app_lb" {
  source   = "github.com/terraform-azurerm-modules/terraform-azurerm-load-balancer?ref=v0.2.1"
  defaults = local.app_vm_defaults

  name = "app"

  load_balancer_rules = [
    {
      protocol      = "Tcp",
      frontend_port = 8080,
      backend_port  = 80
    },
    {
      protocol      = "Tcp",
      frontend_port = 8443,
      backend_port  = 443
    }
  ]
}

module "app" {
  source   = "github.com/terraform-azurerm-modules/terraform-azurerm-linux-vm?ref=v0.2.1"
  defaults = local.app_vm_defaults

  availability_set_name               = "app"
  names                               = ["app-01", "app-02"]
  source_image_id                     = data.azurerm_image.ubuntu_18_04.id
  application_security_groups         = [local.application_security_groups["app"]]
  load_balancer_backend_address_pools = [module.app_lb.load_balancer_backend_address_pool]
}

//======================================================
