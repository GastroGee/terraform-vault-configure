resource "vault_mount" "aws" {
  path = "accounts/aws"
  type = "aws"
}


resource "vault_auth_backend" "approle" {
  type = "approle"
}

resource "vault_mount" "secrets" {
  path        = "secrets"
  type        = "generic"
  description = "secrets for teams"
}

// vault mounts 
resource "vault_mount" "kv2" {
  path        = "kv2"
  type        = "kv"
  description = "kv2 secrets for teams"

  options = {
    version = "2"
  }
}
// Lets mount totp as well
resource "vault_mount" "totp" {
  path        = "totp"
  type        = "totp"
  description = "TOTP code generator"
}

// Hey github where are you 
# https://www.vaultproject.io/api/system/plugins-catalog#parameters
resource "vault_generic_endpoint" "plugin" {
  path           = "sys/plugins/catalog/secret/vault-plugin-secrets-github"
  disable_read   = true
  disable_delete = true
  # DONT FORGET TO UPDATE SHA as you update plugin version
  data_json = <<EOT
{
  "type":"secret",
  "command":"vault-plugin-secrets-github",
  "sha256":"5f68b69506b690636578329d373febdd78140f1e2303af392b91be9bac22f998"
}
EOT
}

# # https://github.com/hashicorp/terraform-provider-vault/issues/623
resource "vault_mount" "github" {
  path        = "github"
  type        = "vault-plugin-secrets-github"
  description = "Mount for generating ephemeral, finely-scoped GH tokens"
  depends_on = [
    vault_generic_endpoint.plugin,
  ]
}


# // Only do this in testing, your private key should be secured safely somewhere terraform has direct access to
data "local_file" "github_private_key" {
    filename = "${path.module}/github/vaultgithub.pem"
}

# https://github.com/martinbaillie/vault-plugin-secrets-github/issues/23
resource "vault_generic_endpoint" "github-config" {
  path  = "${vault_mount.github.path}/config"
  data_json = jsonencode({
    "app_id"  = var.app_id
    "ins_id"  = var.installation_id
    "prv_key" = data.local_file.github_private_key.content
  })
  ignore_absent_fields = true
}