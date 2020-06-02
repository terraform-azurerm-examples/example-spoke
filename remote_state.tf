
data "terraform_remote_state" "hub" {
  backend = "azurerm"

  config = {
    resource_group_name  = "terraform"
    storage_account_name = "terraformsx80gl24bpp83fh"
    container_name       = "tfstate"
    key                  = "hub.tfstate"
  }
}
