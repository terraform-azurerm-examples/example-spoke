
resource "azurerm_public_ip" "appgw" {
  name                = "appgw-pip"
  resource_group_name = azurerm_resource_group.spoke.name
  location            = azurerm_resource_group.spoke.location
  tags                = azurerm_resource_group.spoke.tags

  sku               = "Standard"
  allocation_method = "Static"
  domain_name_label = "appgw-${var.spoke}-${random_string.spoke.result}"
}

resource "azurerm_application_gateway" "appgw" {
  name                = "appgw"
  resource_group_name = azurerm_resource_group.spoke.name
  location            = azurerm_resource_group.spoke.location
  tags                = azurerm_resource_group.spoke.tags

  sku {
    name = "Standard_v2"
    tier = "Standard_v2"
  }

  autoscale_configuration {
    min_capacity = 0
    max_capacity = 6
  }

  identity {
    identity_ids = [azurerm_user_assigned_identity.spoke.id]
    type         = "UserAssigned"
  }

  ssl_certificate {
    name                = "self_signed"
    key_vault_secret_id = azurerm_key_vault_certificate.caCert_pfx.secret_id
  }


  gateway_ip_configuration {
    name      = "appGatewayIpConfig"
    subnet_id = azurerm_subnet.AppGw.id
  }

  // ========================================================================

  frontend_ip_configuration {
    name                          = "appGwPublicFrontendIp"
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.appgw.id
  }

  frontend_ip_configuration {
    name                          = "appGwPrivateFrontendIp"
    private_ip_address_allocation = "Static"
    subnet_id                     = azurerm_subnet.AppGw.id
    private_ip_address            = cidrhost(azurerm_subnet.AppGw.address_prefix, -2)
  }

  frontend_port {
    name = "port_80"
    port = 80
  }

  http_listener {
    name                           = "http"
    frontend_ip_configuration_name = "appGwPrivateFrontendIp"
    frontend_port_name             = "port_80"
    protocol                       = "Http"
  }

  frontend_port {
    name = "port_443"
    port = 443
  }

  http_listener {
    name                           = "https_self_signed"
    frontend_ip_configuration_name = "appGwPrivateFrontendIp"
    frontend_port_name             = "port_443"
    protocol                       = "Https"
    ssl_certificate_name           = "self_signed"
  }

  /*
  http_listener {
    name                           = "https_azurecitadel_com"
    frontend_ip_configuration_name = "appGwPrivateFrontendIp"
    frontend_port_name             = "port_443"
    protocol                       = "Https"
    ssl_certificate_name           = "azurecitadel_com"
  }
  */

  // ========================================================================

  backend_address_pool {
    name = "web_pool1"
  }

  backend_http_settings {
    name                  = "https_pool1"
    affinity_cookie_name  = "pool1_cookie"
    cookie_based_affinity = "Enabled"
    host_name             = "azurecitadel.com"
    path                  = "/"
    port                  = 443
    probe_name            = "Https"
    protocol              = "Https"
    request_timeout       = 20

    connection_draining {
      drain_timeout_sec = 60
      enabled           = true
    }
  }

  backend_address_pool {
    name = "web_pool2"
  }

  backend_http_settings {
    name                  = "https_pool2"
    affinity_cookie_name  = "pool2_cookie"
    cookie_based_affinity = "Disabled"
    path                  = "/media/"
    host_name             = "127.0.0.1"
    port                  = 443
    protocol              = "Https"
    request_timeout       = 20
  }

  probe {
    name                = "Https"
    protocol            = "Https"
    host                = "127.0.0.1"
    path                = "/"
    interval            = 30
    timeout             = 30
    unhealthy_threshold = 3
  }

  // ========================================================================


  request_routing_rule {
    name                        = "redirect_http_to_https"
    rule_type                   = "Basic"
    http_listener_name          = "http"
    redirect_configuration_name = "redirect_http_to_https"
  }

  redirect_configuration {
    name                 = "redirect_http_to_https"
    redirect_type        = "Permanent"
    target_listener_name = "https_self_signed"
    include_path         = true
    include_query_string = true
  }

  request_routing_rule {
    name               = "https"
    rule_type          = "PathBasedRouting"
    http_listener_name = "https_self_signed"
    url_path_map_name  = "https_paths"
  }

  url_path_map {
    name                               = "https_paths"
    default_backend_http_settings_name = "https_pool1"
    default_backend_address_pool_name  = "web_pool1"

    path_rule {
      name                       = "applicationpath_to_pool1"
      backend_http_settings_name = "https_pool1"
      backend_address_pool_name  = "web_pool1"
      paths = [
        "/applicationpath/*",
      ]
    }

    path_rule {
      name                       = "application2path_to_pool2"
      backend_http_settings_name = "https_pool2"
      backend_address_pool_name  = "web_pool2"
      paths = [
        "/application2path/*",
      ]
    }
  }
}


locals {
  appgw_backend_pool_id = {
    for bepool in azurerm_application_gateway.appgw.backend_address_pool :
    (bepool.name) => bepool.id
  }
}

output "appgw" {
  value = azurerm_application_gateway.appgw
}

output "appgw-pip" {
  value = azurerm_public_ip.appgw
}

output "bepoolids" {
  value = {
    for bepool in azurerm_application_gateway.appgw.backend_address_pool :
    (bepool.name) => bepool.id
  }
}
