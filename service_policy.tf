# // This section allows me to map services to vault KV policies 
# // So say i have a service called jenkins, i can map its KV path to kv2/services/jenkins/*

locals {
    services_to_policies = {
        for service in local.services :
        service => concat(
            tolist(lookup(var.additional_service_policies, service, []))
        )
    }

  // Creates the data structure that maps a given service name
  // to the associated IAM roles 
    services_to_iam_principals = {
        for service in keys(var.iam_service_mappings) :
        service => flatten([
        for iam_role in keys(var.iam_service_mappings[service]) :
        [
            for account in var.iam_service_mappings[service][iam_role] : [
            "arn:aws:iam::${local.account_name_map[account]}:role/${iam_role}",
            "arn:aws:sts::${local.account_name_map[account]}:assumed-role/${iam_role}"
            ]
        ]
        ])
    }
}

// This configures vault to given the associated policies to the associated
// IAM Principals.
resource "vault_aws_auth_backend_role" "iam" {
  for_each                 = var.iam_service_mappings
  backend                  = "aws"
  role                     = each.key
  auth_type                = "iam"
  bound_iam_principal_arns = local.services_to_iam_principals[each.key]
  token_policies           = local.services_to_policies[each.key]
  # the principals don't need to exist when this is provisioned 
  # as those principals are controlled by other teams
  resolve_aws_unique_ids = false
}

# # Per https://www.vaultproject.io/docs/auth/aws.html#cross-account-access for vault to be
# # able to authenticate an iam principal, it must have in it's configuration for each account
# # the role to assume that is used merely to validate authentication.  
resource "vault_aws_auth_backend_sts_role" "role" {
  for_each   = var.account_name_map
  backend    = "aws"
  account_id = each.key
  sts_role   = "arn:aws:iam::${each.key}:role/vault-readonly"
}
