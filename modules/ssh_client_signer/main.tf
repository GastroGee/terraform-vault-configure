variable "prod_enabled" {
  default = false
}

variable "default_user" {
  default = "ubuntu"
}

variable "service_name" {}

locals {
  role_name    = "ssh-client-signer-${var.service_name}"
}

// Create a mount for SSH signing
resource "vault_mount" "ssh_client_signer" {
  path = "ssh-client-signer-${var.service_name}"
  type = "ssh"
}

// make sense to create a policy as well
data "vault_policy_document" "ssh_client_signer_admin" {
  rule {
    path         = "${vault_mount.ssh_client_signer.path}/*"
    capabilities = ["create", "update", "read", "delete"]
    description  = "Manage SSH client signer engine"
  }
}

resource "vault_policy" "ssh_client_signer_admin" {
  name   = "ssh-client-signer-${var.service_name}-admin"
  policy = data.vault_policy_document.ssh_client_signer_admin.hcl
}


// Authorize clients
resource "vault_ssh_secret_backend_role" "ssh_client_signer" {
  depends_on = [vault_policy.ssh_client_signer_admin]

  name                    = local.role_name
  backend                 = vault_mount.ssh_client_signer.path
  key_type                = "ca"
  allow_user_certificates = true
  allowed_users           = var.default_user
  default_user            = var.default_user
  algorithm_signer        = "rsa-sha2-512"
  max_ttl                 = "14400" # Sufficient time?
}

resource "vault_ssh_secret_backend_ca" "ssh_client_signer" {
  depends_on = [vault_policy.ssh_client_signer_admin]

  backend              = vault_mount.ssh_client_signer.path
  generate_signing_key = true
}

// COnfigure Policies 
resource "vault_policy" "ssh_client_signer" {
  name  = local.role_name

  policy = <<EOT
    path "${join("", vault_mount.ssh_client_signer.*.path)}/roles/${local.role_name}" {
        policy = "write"
    }
    path "${join("", vault_mount.ssh_client_signer.*.path)}/roles/${local.role_name}" {
        policy = "read"
    }
    path "${join("", vault_mount.ssh_client_signer.*.path)}/sign/${local.role_name}" {
        policy = "write"
    }
EOT
}

// What outputs should be printed on screen post run 

output "policies" {
  value = [local.role_name]
}

output "admin_policies" {
  value = vault_policy.ssh_client_signer_admin.name
}

output "public_key" {
  value = vault_ssh_secret_backend_ca.ssh_client_signer.public_key
}

