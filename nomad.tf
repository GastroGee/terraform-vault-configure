# Create Nomad Server policy
# https://learn.hashicorp.com/tutorials/nomad/vault-postgres?in=nomad/integrate-vault
data "vault_policy_document" "nomad-server" {
  rule {
    path         = "auth/token/create/nomad-cluster"
    capabilities = ["update"]
    description  = "Allow creating tokens under nomad-cluster token role. The role name should be updated if nomad-cluster is not used"
  }
  rule {
    path         = "auth/token/roles/nomad-cluster"
    capabilities = ["read"]
    description  = "Allow looking up nomad-cluster token role. The role name should be updated if nomad-cluster is not used"
  }
  rule {
    path         = "auth/token/lookup-self"
    capabilities = ["read"]
    description  = "Allow looking up the token passed to Nomad to validate the token has the proper capabilities. This is provided by the default policy."
  }
  rule {
    path         = "auth/token/lookup"
    capabilities = ["update"]
    description  = "Allow looking up incoming tokens to validate they have permissions to access the tokens they are requesting. This is only required if allow_unauthenticated is set to false."
  }
  rule {
    path         = "auth/token/revoke-accessor"
    capabilities = ["update"]
    description  = "Allow revoking tokens that should no longer exist. This allows revoking tokens for dead tasks."
  }
  rule {
    path         = "sys/capabilities-self"
    capabilities = ["update"]
    description  = "Allow checking the capabilities of our own token. This is used to validate the token upon startup."
  }
  rule {
    path         = "auth/token/renew-self"
    capabilities = ["update"]
    description  = "Allow our own token to be renewed."
  }
}

resource "vault_policy" "nomad-server-policy" {
  name   = "nomad-server"
  policy = data.vault_policy_document.nomad-server.hcl
}

# Create Nomad-cluster token role that allows nomad to dynamically retreieve secrets from Vault
resource "vault_token_auth_backend_role" "nomad-cluster-role" {
  role_name              = "nomad-cluster"
  // disallow the nomad approle created under approle.tf
  disallowed_policies    = ["nomad-server", "admin"]
  orphan                 = true
  renewable              = true
  token_explicit_max_ttl = 0
  token_period           = "86400" //24 hr renewal
}

# Create an AppRole auth backend role that has the nomad server policy attached
resource "vault_approle_auth_backend_role" "nomad-server-role" {
  backend        = "approle"
  role_name      = "nomad-server"
  token_policies = ["default", "nomad-server"]

  token_ttl = "43200" # 12hr renewal

  token_max_ttl = "172800" # 2d max
}

