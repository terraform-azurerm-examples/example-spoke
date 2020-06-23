// Note that some of the .tf files also have variable and output blocks to make them individually complete


variable "spoke" {
  type        = string
  description = "Used for both the vnet and the resource group, and to prefix resources."
  default     = "spoke"
}

variable "spoke_vnet_address_space" {
  description = "List of address spaces for the virtual network. One /24 address space is expected."
  type        = list(string)
  default     = ["10.0.0.0/24"]
}

variable "dns_servers" {
  description = "Optional list of DNS server IP addresses."
  type        = list(string)
  default     = null
}

variable "aad" {
  description = "Optional list of AAD objectIds to add to key vault access."
  type        = list(string)
  default     = []
}

// -----------------------------------------------------------

variable "application_gateway_public_frontend" {
  description = "Boolean to specify listeners on the public frontend rather than the default private frontend."
  type        = bool
  default     = false
}

variable "application_gateway_pools" {
  description = "List of backend pools to create in the application gateway. Also used to create matching application security groups."
  type        = list
  default     = []
}

variable "application_gateway_path_map" {
  description = "Map of lists, keyed by application gateway backend pools and with a list if URL paths."
  type        = map(list(string))
  default     = {}
}

variable "application_gateway_default_uri" {
  description = "Default URI to use if none of the path maps apply."
  type        = string
  default     = ""
}

// -----------------------------------------------------------

variable "tenant_id" {
  description = "The AAD tenant guid."
  type        = string
}

variable "subscription_id" {
  description = "The subscription guid."
  type        = string
}

// variable "client_id" {
//   description = "The application id for the service principal."
//   type        = string
// }
//
// variable "client_secret" {
//   type        = string
//   description = "The password for the service principal."
//   default     = ""
// }

variable "location" {
  default = "West Europe"
}

variable "tags" {
  type = object({
    owner         = string
    business_unit = string
    costcode      = number
    downtime      = string
    env           = string
    enforce       = bool
  })
}
