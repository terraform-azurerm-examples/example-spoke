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

module "web_pool1_set" {
  source            = "github.com/terraform-azurerm-modules/terraform-azurerm-set" #?ref=v0.1"
  defaults          = local.web_set_defaults
  module_depends_on = [local.application_gateway_backend_pool_id]

  name                                = "web-pool1"
  application_gateway_backend_pool_id = local.application_gateway_backend_pool_id["web_pool1"]
}

module "web_pool1_vms" {
  // source            = "github.com/terraform-azurerm-modules/terraform-azurerm-linux-vm" #?ref=v0.1"
  source            = "github.com/terraform-azurerm-modules/terraform-azurerm-linux-vm" #?ref=v0.1"
  defaults          = local.web_vm_defaults
  module_depends_on = [module.web_pool1_set]

  attachType = "ApplicationGateway"
  attach     = module.web_pool1_set.set_ids

  names           = ["web-pool1-a", "web-pool1-b", "web-pool1-c"]
  source_image_id = data.azurerm_image.ubuntu_18_04.id
}
