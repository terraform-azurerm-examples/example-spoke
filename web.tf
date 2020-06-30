resource "azurerm_resource_group" "spoke_web" {
  name     = "${var.spoke}-web-vms"
  location = var.location
  tags     = var.tags
}

locals {
  web_vm_defaults = {
    resource_group_name  = azurerm_resource_group.spoke_web.name
    location             = azurerm_resource_group.spoke_web.location
    tags                 = azurerm_resource_group.spoke_web.tags
    admin_username       = "ubuntu"
    admin_ssh_public_key = azurerm_key_vault_secret.ssh_pub_key["ubuntu"].value
    additional_ssh_keys  = []
    vm_size              = "Standard_B1ls"
    storage_account_type = "Standard_LRS"
    identity_id          = azurerm_user_assigned_identity.spoke.id
    subnet_id            = azurerm_subnet.web.id
    boot_diagnostics_uri = azurerm_storage_account.boot_diagnostics.primary_blob_endpoint
  }
}

//======================================================

resource "azurerm_application_security_group" "web" {
  for_each            = toset(var.application_gateway_backend_pool_names)
  name                = each.value
  resource_group_name = azurerm_resource_group.spoke_web.name
  location            = azurerm_resource_group.spoke_web.location
  tags                = azurerm_resource_group.spoke_web.tags
}

module "web_vmss" {
  source = "github.com/terraform-azurerm-modules/terraform-azurerm-linux-vmss?ref=v0.2.1"
  // source   = "../../../modules/vmss"
  defaults = local.web_vm_defaults

  name                                         = "web"
  instances                                    = 3
  source_image_id                              = data.azurerm_image.ubuntu_18_04.id
  application_security_group_ids               = [azurerm_application_security_group.web["web"].id]
  application_gateway_backend_address_pool_ids = [local.application_gateway_backend_pools["web"].id]
}

module "media_vmss" {
  source = "github.com/terraform-azurerm-modules/terraform-azurerm-linux-vmss?ref=v0.2.1"
  // source   = "../../../modules/vmss"
  defaults = local.web_vm_defaults

  name                                         = "media"
  instances                                    = 2
  source_image_id                              = data.azurerm_image.ubuntu_18_04.id
  application_security_group_ids               = [azurerm_application_security_group.web["media"].id]
  application_gateway_backend_address_pool_ids = [local.application_gateway_backend_pools["media"].id]
}

module "catalog_vmss" {
  source = "github.com/terraform-azurerm-modules/terraform-azurerm-linux-vmss?ref=v0.2.1"
  // source   = "../../../modules/vmss"
  defaults = local.web_vm_defaults

  name                                         = "catalog"
  instances                                    = 2
  source_image_id                              = data.azurerm_image.ubuntu_18_04.id
  application_security_group_ids               = [azurerm_application_security_group.web["catalog"].id]
  application_gateway_backend_address_pool_ids = [local.application_gateway_backend_pools["catalog"].id]
}

//======================================================
