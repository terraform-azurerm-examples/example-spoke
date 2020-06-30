# example-spoke

This is an example Terraform config creating a spoke in a hub and spoke topology. As an example repo for learning purposes then you are encouraged to copy any of the Terraform from it, or fork it and make your own changes.

It is a work in progress and may be updated at any point. It will be used for a number of training labs in [Azure Citadel](https://azurecitadel.com).

## Pre-requirements

You must have:

* an existing hub virtual network containing either a VPN Gateway or ExpressRoute Gateway
* access to the Terraform state file for the hub

See the <https://github.com/terraform-azurerm-modules/example-hub>.

## tl;dr

One example usage once you've cloned the repo:

* [Optional] Bootstrap
  * Preview the bootstrap_README.md in the storage account created by [terraform-bootstrap](https://github.com/terraform-azurerm-modules/terraform-bootstrap)
  * Download the bootstrap files
  * Set the key in backend.tf to your Terraform statefile name, e.g. example-spoke.tfstate
* `mv remote_state.tf.example remote_state.tf`
  * Configure either the azurerm or local version of the terraform_remote_state data block
  * Remove the unwanted example
* Create a caCert.pfx
  * This will added as a certificate in the key vault to be used by the App GW
  * An example caCert.pfx is included for training purposes
* `mv terraform.tfvars.example terraform.tfvars`
  * Edit the file as required
* `terraform init`
* `terraform validate`
* `terraform plan`
* `terraform apply`

The resources will be created in a single resource group called example-hub.

Read the full readme for more information and options.

Note that the following files are taking from terraform-backend's bootstrap outputs. Refer to the README.md :

* azurerm_provider.tf
* backend.tf
* client_secret.tf

***More details to be added***
