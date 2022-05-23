// This module allows vault to generate nomad tokens 
// This is slightly different from nomad having access to vault secrets 
// Generate Nomad Tokens with Hashicorp Vault 
// https://learn.hashicorp.com/tutorials/nomad/vault-nomad-secrets?in=nomad/integrate-vault


variable "description" {
    description = "Description"
    default = "The Nomad secret backend for Vault generates Nomad ACL tokens dynamically based on pre-existing Nomad ACL policies."
}
variable "nomad_addr" {
    description = "Specifies the address of the Nomad instance, provided as 'protocol://host:port' like 'http://127.0.0.1:4646'"
}

variable "nomad_token" {
    description = "This is typically a Nomad Management Token"
}

# variable "nomad_token_ttl" {
#     description = "Specifies the ttl of the lease for the generated token."
# }

variable "default_lease_ttl_seconds" {
    description = "Default lease duration for secrets in seconds."
    default = 3600
}

variable "max_lease_ttl_seconds" {
    description = "Max lease on Tokens"
    default = 7200
}

variable "max_ttl" {
    description = "Maximum possible lease duration for secrets in seconds."
    default = 240
}

variable "ttl" {
    description = "Maximum possible lease duration for secrets in seconds."
    default = 120
}


resource "vault_nomad_secret_backend" "config" {
    backend                   = "nomad"
    description               = var.description
    // this could be a variable 
    default_lease_ttl_seconds = var.default_lease_ttl_seconds
    max_lease_ttl_seconds     = var.max_lease_ttl_seconds
    max_ttl                   = var.max_ttl
    address                   = var.nomad_addr
    token                     = var.nomad_token
    ttl                       = var.ttl
}

resource "vault_nomad_secret_role" "developer" {
  backend   = vault_nomad_secret_backend.config.backend
  role      = "developer"
  type      = "client"
  policies  = ["nomad_developer"]
}

resource "vault_nomad_secret_role" "operator" {
  backend   = vault_nomad_secret_backend.config.backend
  role      = "developer"
  type      = "client"
  policies  = ["nomad_operator"]
}


data "vault_policy_document" "nomad_developer" {

  rule {
    path         = "nomad/creds/developer"
    capabilities = ["read", "update", "create"]
    description  = "read nomad job"
  }
}
resource "vault_policy" "nomad_developer" {
  name   = "nomad_developer"
  policy = data.vault_policy_document.nomad_developer.hcl
}

data "vault_policy_document" "nomad_operator" {
  rule {
    path         = "nomad/creds/operator"
    capabilities = ["list", "delete"]
    description  = "The production operations team needs to be able to perform cluster maintenance and view the workload"
  }
}
resource "vault_policy" "nomad_operator" {
  name   = "nomad_operator"
  policy = data.vault_policy_document.nomad_operator.hcl
}



