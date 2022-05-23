// Lets create a bunch of policies in vault that we could assign to a user say admin
// The first allows admin user to write to any kv2 path 
// https://www.vaultproject.io/docs/secrets/aws
data "vault_policy_document" "kv2_admin" {
  rule {
    path         = "kv2/*"
    capabilities = ["create", "read", "update", "delete", "list", "sudo"]
    description  = "List, create, update, and delete key/value secrets"
  }
}

resource "vault_policy" "kv2_admin" {
  name   = "secrets-admin"
  policy = data.vault_policy_document.kv2_admin.hcl
}


// This allows admin to get AWS Creds for any account 
data "vault_policy_document" "aws_admin" {
  rule {
    path         = "accounts/aws/roles/*"
    capabilities = ["read", "list", "delete", "update"]
    description  = "crud aws secrets"
  }

  rule {
    path         = "accounts/aws/roles"
    capabilities = ["read", "list"]
    description  = "list all the aws secrets we have"
  }

  rule {
    path         = "accounts/aws/sts/*"
    capabilities = ["create", "read", "update", "delete", "list"]
    description  = "generate any aws credential for either the assumed_role or federation_token type"
  }


  rule {
    path         = "accounts/aws/creds/*"
    capabilities = ["create", "read", "update", "delete", "list"]
    description  = "generate any aws credential for the iam_user type"
  }

}

resource "vault_policy" "aws_admin" {
  name   = "aws-admin"
  policy = data.vault_policy_document.aws_admin.hcl
}

// Allows admin to perform PKI tasks 
data "vault_policy_document" "pki_admin" {
  rule {
    path         = "pki_root/*"
    capabilities = ["create", "read", "update", "delete", "list", "sudo"]
    description  = "Manage root pki secrets engine"
  }

  rule {
    path         = "pki_int/*"
    capabilities = ["create", "read", "update", "delete", "list", "sudo"]
    description  = "Manage intermediate pki secrets engine"
  }
}

resource "vault_policy" "pki_admin" {
  name   = "pki-admin"
  policy = data.vault_policy_document.pki_admin.hcl
}

// Allows admin to perform revoke operations
data "vault_policy_document" "revoke_admin" {
  rule {
    path         = "sys/leases/revoke-prefix/accounts/aws/sts/*"
    capabilities = ["sudo", "update"]
    description  = "Revoke access keys generated with AWS Secret Backend"
  }

  rule {
    path         = "auth/token/revoke-accessor"
    capabilities = ["sudo", "update"]
    description  = "Revoke a token and all its children via token accessor"
  }

}

resource "vault_policy" "revoke_admin" {
  name   = "revoke-admin"
  policy = data.vault_policy_document.revoke_admin.hcl
}

// This allows admin to perform consul operations
data "vault_policy_document" "consul_admin" {
  rule {
    path         = "consul/*"
    capabilities = ["create", "read", "update", "delete", "list", "sudo"]
    description  = "Manage Consul secrets engine"
  }

}

resource "vault_policy" "consul_admin" {
  name   = "consul-admin"
  policy = data.vault_policy_document.consul_admin.hcl
}

// Allows admin user to perform totp operations 
data "vault_policy_document" "totp_admin" {
  rule {
    path         = "totp/*"
    capabilities = ["create", "read", "update", "delete", "list", "sudo"]
    description  = "Generates any time-based credentials according to the TOTP standard"
  }
}

resource "vault_policy" "totp_admin" {
  name   = "totp-admin"
  policy = data.vault_policy_document.totp_admin.hcl
}

// Allows admin to see internal counters like metrics and configuration
data "vault_policy_document" "sys_internal_counters_admin" {
  rule {
    path         = "sys/internal/counters/activity"
    capabilities = ["read", "list"]
    description  = "Read and List internal stats counters"
  }
  rule {
    path         = "sys/internal/counters/config"
    capabilities = ["read", "update"]
    description  = "Read and Update internal stats counter configuration"
  }
}

resource "vault_policy" "sys_internal_counters_admin" {
  name   = "sys-internal-counters-admin"
  policy = data.vault_policy_document.sys_internal_counters_admin.hcl
}

// Allows admin to generate ephemeral creds for github and a host of other functions
data "vault_policy_document" "github_admin" {
  rule {
    path         = "github/config"
    capabilities = ["create", "update", "read", "delete", "list"]
    description  = "Manage GitHub secrets engine"
  }
  rule {
    path         = "github/permissionset"
    capabilities = ["create", "update", "read", "delete", "list"]
    description  = "Manage GitHub secrets engine permission sets"
  }
  rule {
    path         = "github/permissionset/*"
    capabilities = ["create", "update", "read", "delete", "list"]
    description  = "Manage GitHub secrets engine permission sets"
  }
  rule {
    path         = "github/permissionsets"
    capabilities = ["create", "update", "read", "delete", "list"]
    description  = "Manage GitHub secrets engine permission sets"
  }
  rule {
    path         = "github/info"
    capabilities = ["read", "list"]
    description  = "Manage GitHub secrets engine permission sets"
  }
  rule {
    path         = "github/metrics"
    capabilities = ["read", "list"]
    description  = "Manage GitHub secrets engine permission sets"
  }
  rule {
    path         = "github/token"
    capabilities = ["update", "read"]
    description  = "Allow for creating ephemeral github tokens"
  }
  rule {
    path         = "github/token/*"
    capabilities = ["update", "read"]
    description  = "Allow for creating ephemeral github tokens"
  }
}

resource "vault_policy" "github_admin" {
  name   = "github-admin"
  policy = data.vault_policy_document.github_admin.hcl
}

