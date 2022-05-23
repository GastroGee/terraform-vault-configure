// Set some variable defaults 
variable "role_name" {
  default = ""
  type    = string
}

variable "aws_accounts" {
  default = {}
  type    = map(string)
}


// Vault allows us to generate emphemeral creds to login to AWS
// This section allows us to pass in AWS account information we would like to set up
// First lets create a policy that interates over each role we want to configure in AWS

resource "vault_policy" "account" {
  for_each = var.aws_accounts

  name = "aws-${each.key}-${var.role_name}"

  policy = <<EOT
    path "accounts/aws/sts/${each.key}-${var.role_name}" {
        policy = "write"
    }
    path "aws/creds/${each.key}-${var.role_name}" {
        policy = "read"
    }
    path "auth/token/create" {
        capabilities = ["create", "read", "update", "list"]
    }
EOT
}

// Create roles on AWs secret backend that maps credentials to the policy from which they are generated 
resource "vault_aws_secret_backend_role" "role" {
  for_each        = var.aws_accounts
  backend         = "accounts/aws"
  credential_type = "assumed_role"
  name            = "${each.key}-${var.role_name}"
  role_arns       = ["arn:aws:iam::${each.value}:role/${var.role_name}"]
}

// We don't use the actual resources to derive the names, because Terraform
// gets stuck in a dependency cycle while trying to eliminate accounts that
// have been removed.
output "policies" {
  value = formatlist("aws-%s-${var.role_name}", keys(var.aws_accounts))
}