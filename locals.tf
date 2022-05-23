 locals {
  policy_names = concat(
    module.aws_admin.policies,
    module.aws_readonly.policies,
    module.aws_readwrite.policies,
    module.kv_services.policies,
    module.ssh_client_signer.policies,
    [vault_policy.aws_admin.name]
   )
   services = toset(var.services)
  }
