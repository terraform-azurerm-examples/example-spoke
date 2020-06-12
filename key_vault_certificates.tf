resource "azurerm_key_vault_certificate" "caCert_pfx" {
  // openssl pkcs12 -export -out caCert.pfx -inkey caKey.pem -in caCert.pem
  name         = "caCert-pfx"
  key_vault_id = azurerm_key_vault.spoke.id

  certificate {
    contents = filebase64("caCert.pfx")
    password = ""
  }

  certificate_policy {
    issuer_parameters {
      name = "Self"
    }

    key_properties {
      exportable = true
      key_size   = 2048
      key_type   = "RSA"
      reuse_key  = false
    }

    secret_properties {
      content_type = "application/x-pkcs12"
    }
  }
}