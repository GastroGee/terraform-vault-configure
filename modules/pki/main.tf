// Mount Vault PKI Backend 
resource "vault_mount" "vault_pki_root" {
  type                  = "pki"
  path                  = "pki_root"
  max_lease_ttl_seconds = 630720000 # 20 years
  description           = "Mount for Root CA"
}

// Generates a new self-signed CA certificate and private keys for the PKI Secret Backend. 
resource "vault_pki_secret_backend_root_cert" "root_certificate" {
  backend     = vault_mount.vault_pki_root.path
  type        = "internal"
  common_name = "Vault Root 01"

  ou           = "Platform Engineering"
  organization = "Gastro LLC."
  locality     = "Minneapolis"
  province     = "Minnesota"
  country      = "US"
  ttl          = "175200h" # An awfully Long time

  format             = "pem"
  private_key_format = "der"
  key_type           = "rsa"
  key_bits           = 4096
}

//  setting the issuing certificate endpoints, CRL distribution points,
resource "vault_pki_secret_backend_config_urls" "config_urls" {
  backend                 = vault_mount.vault_pki_root.path
  issuing_certificates    = ["http://127.0.0.1:8200/v1/pki/ca"]
  crl_distribution_points = ["http://127.0.0.1:8200/v1/pki/crl"]
}

// Create a mount point for vault intermediary
resource "vault_mount" "vault_pki_intermediary" {
  type                  = "pki"
  path                  = "pki_int"
  max_lease_ttl_seconds = 315360000 # 10 years
  description           = "Mount for Intermediary CA"
}

// Create an intermediary CA CSR 
resource "vault_pki_secret_backend_intermediate_cert_request" "intermediate_ca_csr" {
  depends_on = [vault_mount.vault_pki_intermediary]

  backend = vault_mount.vault_pki_intermediary.path

  type        = "internal"
  common_name = "Vault Intermediary 01"
  ou           = "Platform Engineering"
  organization = "Gastro LLC."
  locality     = "Minneapolis"
  province     = "Minnesota"
  country      = "US"

  format             = "pem"
  private_key_format = "der"
  key_type           = "rsa"
  key_bits           = 4096
}

// Creates PKI certificate
resource "vault_pki_secret_backend_root_sign_intermediate" "root_sign_intermediate" {
  depends_on = [vault_pki_secret_backend_intermediate_cert_request.intermediate_ca_csr]

  backend = vault_mount.vault_pki_root.path

  ttl = "87600h" # Another awfully long time

  csr          = vault_pki_secret_backend_intermediate_cert_request.intermediate_ca_csr.csr
  ou           = "Platform Engineering"
  organization = "Gastro LLC"
  locality     = "Minneapolis"
  province     = "Minnesota"
  country      = "US"
  common_name = "Vault Intermediary 01"
}

# Take created cert and import back into vault
resource "vault_pki_secret_backend_intermediate_set_signed" "intermediate_signed_cert" {
  backend = vault_mount.vault_pki_intermediary.path

  certificate = vault_pki_secret_backend_root_sign_intermediate.root_sign_intermediate.certificate
}

// now we can create a role that generates certs for say nomad mtls 
resource "vault_pki_secret_backend_role" "nomad-cluster" {
  backend          = vault_mount.vault_pki_intermediary.path
  name             = "nomad-cluster"
  allowed_domains  = ["global.nomad"]
  allow_subdomains = true
  allow_any_name   = true
  ttl              = 3888000 # 45 days
  require_cn       = false
  generate_lease   = true
  key_usage        = ["DigitalSignature", "KeyAgreement", "KeyEncipherment"]
}

# Policy for the role above
data "vault_policy_document" "tlspolicydocument" {
  rule {
    path         = "pki_int/issue/nomad-cluster"
    capabilities = ["update"]
  }
}
resource "vault_policy" "tlspolicy" {
  name   = "tls-policy"
  policy = data.vault_policy_document.tlspolicydocument.hcl
}


output "intermediary_csr" {
  value = vault_pki_secret_backend_intermediate_cert_request.intermediate_ca_csr
}