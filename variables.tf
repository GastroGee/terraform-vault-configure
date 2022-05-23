variable "app_id" {
    default = "202944"
}

variable "installation_id" {
    default = "25854749"
}

variable "kv_group_name" {
    default = "services"
}


variable "nomad_token" {}

variable "nomad_addr" {}


variable "services" {
    type = list
    default = ["concourse", "artifactory", "jenkins", "nomad-server", "packer"]
}

variable "vault_address" {
  default = "http://localhost:8200"
}


variable "account_name_map" {
    description = <<EOH
        a map of AWS account names and account IDs. For instance,
        account_name_map = {
            "12456879 = "Prod"
        }
        would allow vault create a role for each account ID
    EOH
    default = {
         "ogunsegha" = "281080354138"
    }
}

/// So say we have a couple of policy that needs to be assumed by other roles not neccesary in its creation stream; we could use this variable to map them 

variable "additional_service_policies" {
  description = <<-EOH
    For each service, we automatically create a read and write policy to the corresponding
    kv path.
    Any other policies declared in this map are added to the corresponding service principal for
    the automatically created approle or the iam instance profile if so specified.  For example

    ```additional_service_policies = {

      nomad = ["nomad-server-policy"]
    }```
    would mean that the nomad-server-policy would be attached
    to the nomad principal.
  EOH

  type    = map(list(string))
  default = {}
}

variable "iam_service_mappings" {
  description = <<EOH
    for each service declared, you can give a role name, 
    along with a list of account names that can map to this service principal.  For instance

    iam_service_mappings = {
      hello-world = {
          "hello-world*" = ["prod", "dev", "stage", "canary"]
      }
    }

    would allow an iam principal that matches role/hello-world* in the prod, 
    dev, stage, or canary account to have a token that allowed it to write to the 
    secrets/service/hello-world path in vault or get a consul http token that allows one to write 
    to services/hello-world
  EOH
  default     = {}
}