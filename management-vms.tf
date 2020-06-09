locals {
  set_defaults = {
    resource_group_name = azurerm_resource_group.spoke.name
    location            = azurerm_resource_group.spoke.location
    tags                = azurerm_resource_group.spoke.tags
    availability_set    = true
    load_balancer       = true
    subnet_id           = azurerm_subnet.Web.id
  }

  vm_defaults = {
    resource_group_name  = azurerm_resource_group.spoke.name
    location             = azurerm_resource_group.spoke.location
    tags                 = azurerm_resource_group.spoke.tags
    admin_username       = "ubuntu"
    admin_ssh_public_key = azurerm_key_vault_secret.ssh_pub_key["ubuntu"].value
    additional_ssh_keys  = []
    vm_size              = "Standard_B1ls"
    storage_account_type = "Standard_LRS"
    subnet_id            = azurerm_subnet.Web.id
    boot_diagnostics_uri = azurerm_storage_account.boot_diagnostics.primary_blob_endpoint
  }
}

module "single" {
  source   = "github.com/terraform-azurerm-modules/terraform-azurerm-linux-vm" #?ref=v0.1"
  defaults = local.vm_defaults

  name            = "single"
  source_image_id = data.azurerm_image.ubuntu_18_04.id
}


module "testbed_set" {
  source   = "github.com/terraform-azurerm-modules/terraform-azurerm-set" #?ref=v0.1"
  defaults = local.set_defaults

  name = "testbed"
}

module "testbed" {
  source   = "github.com/terraform-azurerm-modules/terraform-azurerm-linux-vm" #?ref=v0.1"
  defaults = local.vm_defaults

  module_depends_on = [module.testbed_set]
  attachType        = "All"
  attach            = module.testbed_set.set_ids

  names           = ["testbed-a", "testbed-b", "testbed-c"]
  source_image_id = data.azurerm_image.ubuntu_18_04.id
}

module "nodefaults" {
  source              = "github.com/terraform-azurerm-modules/terraform-azurerm-linux-vm" #?ref=v0.1"
  resource_group_name = azurerm_resource_group.spoke.name
  location            = azurerm_resource_group.spoke.location
  tags                = azurerm_resource_group.spoke.tags

  name                 = "nodefaults"
  source_image_id      = data.azurerm_shared_image.ubuntu_18_04.id
  subnet_id            = azurerm_subnet.App.id
  boot_diagnostics_uri = azurerm_storage_account.boot_diagnostics.primary_blob_endpoint
}
