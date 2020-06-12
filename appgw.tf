
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

  backend_address_pool {
    name = "web_pool1"
  }

  backend_address_pool {
    name = "web_pool2"
  }

  backend_http_settings {
    name                                = "https_pool1"
    affinity_cookie_name                = "pool1_cookie"
    cookie_based_affinity               = "Enabled"
    host_name                           = "azurecitadel.com"
    path                                = "/"
    pick_host_name_from_backend_address = false
    port                                = 443
    probe_name                          = "Https"
    protocol                            = "Https"
    request_timeout                     = 20

    connection_draining {
      drain_timeout_sec = 60
      enabled           = true
    }
  }

  backend_http_settings {
    name                                = "https_pool2"
    affinity_cookie_name                = "pool2_cookie"
    cookie_based_affinity               = "Enabled"
    path                                = "/app2"
    pick_host_name_from_backend_address = false
    port                                = 443
    protocol                            = "Https"
    request_timeout                     = 20

    connection_draining {
      drain_timeout_sec = 60
      enabled           = true
    }
  }

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

  gateway_ip_configuration {
    name      = "appGatewayIpConfig"
    subnet_id = azurerm_subnet.AppGw.id
  }

  frontend_port {
    name = "port_80"
    port = 80
  }

  frontend_port {
    name = "port_443"
    port = 443
  }

  http_listener {
    name                           = "private_https"
    frontend_ip_configuration_name = "appGwPrivateFrontendIp"
    frontend_port_name             = "port_443"
    protocol                       = "Https"
    ssl_certificate_name           = "private_https"
  }

  http_listener {
    name                           = "private_http"
    frontend_ip_configuration_name = "appGwPrivateFrontendIp"
    frontend_port_name             = "port_80"
    protocol                       = "Http"
  }

  identity {
    identity_ids = [azurerm_user_assigned_identity.spoke.id]
    type         = "UserAssigned"
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

  redirect_configuration {
    name                 = "private_http_to_https"
    redirect_type        = "Permanent"
    target_listener_name = "private_https"
    include_path         = true
    include_query_string = true
  }

  request_routing_rule {
    name                        = "private_http_to_https"
    rule_type                   = "Basic"
    http_listener_name          = "private_http"
    redirect_configuration_name = "private_http_to_https"
  }

  request_routing_rule {
    name               = "private_https"
    rule_type          = "PathBasedRouting"
    http_listener_name = "private_https"
    url_path_map_name  = "private_https"
  }

  ssl_certificate {
    name                = "private_https"
    key_vault_secret_id = "https://example-spoke-d5nsem40ua.vault.azure.net/secrets/caCert-pfx/e51ec1428f30446ea4bea438896403d5"
  }

  url_path_map {
    name                               = "private_https"
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
