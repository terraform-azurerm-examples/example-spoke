
data "terraform_remote_state" "hub" {
  backend = "azurerm"

  config = {
    resource_group_name  = "terraform"
    storage_account_name = "terraformo7odvr3icext3gp"
    container_name       = "tfstate"
    key                  = "hub.tfstate"
  }
}
