locals {
  default_uri = var.application_gateway_default_uri != null ? true : false

  // Map used by VM and VMSS
  application_gateway_backend_pools = {
    for bepool in azurerm_application_gateway.appgw.backend_address_pool :
    (bepool.name) => {
      name = bepool.name
      id   = bepool.id
    }
  }
}

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
    subnet_id = azurerm_subnet.app_gw.id
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
    subnet_id                     = azurerm_subnet.app_gw.id
    private_ip_address            = cidrhost(azurerm_subnet.app_gw.address_prefix, -2)
  }

  frontend_port {
    name = "port_80"
    port = 80
  }

  http_listener {
    name                           = "http"
    frontend_ip_configuration_name = var.application_gateway_public_frontend ? "appGwPublicFrontendIp" : "appGwPrivateFrontendIp"
    frontend_port_name             = "port_80"
    protocol                       = "Http"
  }

  frontend_port {
    name = "port_443"
    port = 443
  }

  http_listener {
    name                           = "https_self_signed"
    frontend_ip_configuration_name = var.application_gateway_public_frontend ? "appGwPublicFrontendIp" : "appGwPrivateFrontendIp"
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

  dynamic "backend_address_pool" {
    for_each = var.application_gateway_backend_pool_names

    content {
      name = backend_address_pool.value
    }
  }

  dynamic "backend_http_settings" {
    // May want to complicate the path map just to include different settings in here
    // Or create a couple of standards and reference them
    for_each = var.application_gateway_path_map

    content {
      name                  = backend_http_settings.key
      affinity_cookie_name  = "${backend_http_settings.key}_cookie"
      cookie_based_affinity = "Disabled"
      path                  = "/"
      host_name             = "127.0.0.1"
      port                  = 80
      protocol              = "Http"
      request_timeout       = 20
    }
  }

  backend_http_settings {
    name                  = "default_backend_http_settings"
    affinity_cookie_name  = "default_backend_http_settings_cookie"
    cookie_based_affinity = "Disabled"
    path                  = "/"
    host_name             = "127.0.0.1"
    port                  = 80
    protocol              = "Http"
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


  probe {
    name                = "Http"
    protocol            = "Http"
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
    name = "https_paths"

    // Inly one of these defaults should be set
    default_redirect_configuration_name = local.default_uri ? "default_redirect_configuration" : null
    default_backend_address_pool_name   = local.default_uri ? null : var.application_gateway_default_backend_address_pool_name
    default_backend_http_settings_name  = local.default_uri ? null : "default_backend_http_settings"

    dynamic "path_rule" {
      for_each = var.application_gateway_path_map

      content {
        name                       = path_rule.key
        backend_http_settings_name = path_rule.key
        backend_address_pool_name  = path_rule.key
        paths                      = path_rule.value
      }
    }
  }

  dynamic "redirect_configuration" {
    for_each = toset(local.default_uri ? [1] : [])

    content {
      name                 = "default_redirect_configuration"
      redirect_type        = "Permanent"
      target_url           = var.application_gateway_default_uri
      include_path         = false
      include_query_string = false
    }
  }
}

output "application_gateway" {
  value = azurerm_application_gateway.appgw
}

output "application_gateway_pip" {
  value = azurerm_public_ip.appgw
}

output "application_gateway_backend_pools" {
  value = local.application_gateway_backend_pools
}
