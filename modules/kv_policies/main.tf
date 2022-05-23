// In this section, we are hoping we can generate a KV2 Path for say every team in our organization
// this would represent a directory within the vault pathn

variable "kv_group_name" {
  description = "e.g. services"
}

variable "kv_path" {
  default = "kv2"
}

variable "services" {
  type = list(string)
}

// for each group provided, we are attempting to create a read and write policy
locals {
  services = toset(var.services)

  policies = concat(
    formatlist("kv2-${var.kv_group_name}-%s-write", var.services),
    formatlist("kv2-${var.kv_group_name}-%s-read", var.services)
  )

}

// Allows reads at kv2/data/prod/services/<servicename> for instance
resource "vault_policy" "read" {
  for_each = local.services
  name     = "kv2-${var.kv_group_name}-${each.key}-read"

  policy = <<EOT
    path "${var.kv_path}/data/${var.kv_group_name}/${each.key}" {
        capabilities = [ "read", "list"]
    }
    path "${var.kv_path}/data/${var.kv_group_name}/${each.key}/*" {
        capabilities = [ "read", "list"]
    }
    path "${var.kv_path}/metadata/${var.kv_group_name}/${each.key}*" {
        capabilities = ["read", "list"]
    }
    path "${var.kv_path}/metadata/${var.kv_group_name}/${each.key}/*" {
        capabilities = ["read", "list"]
    }
EOT

}

# Allows writes at kv2/data/prod/services/<servicename> for instance
resource "vault_policy" "write" {
  for_each = local.services
  name     = "kv2-${var.kv_group_name}-${each.key}-write"

  policy = <<EOT
    path "${var.kv_path}/data/${var.kv_group_name}/${each.key}" {
        capabilities = ["create", "read", "update", "delete", "list"]
    }
    path "${var.kv_path}/data/${var.kv_group_name}/${each.key}/*" {
        capabilities = ["create", "read", "update", "delete", "list"]
    }
    path "${var.kv_path}/metadata/${var.kv_group_name}/${each.key}*" {
        capabilities = ["list", "delete", "read", "update"]
    }
    path "${var.kv_path}/metadata/${var.kv_group_name}/${each.key}/*" {
        capabilities = ["list", "delete", "read", "update"]
    }
    path "${var.kv_path}/destroy/${var.kv_group_name}/${each.key}*" {
        capabilities = ["update"]
    }
    path "${var.kv_path}/destroy/${var.kv_group_name}/${each.key}/*" {
        capabilities = ["update"]
    }
    path "${var.kv_path}/delete/${var.kv_group_name}/${each.key}*" {
        capabilities = ["update"]
    }
    path "${var.kv_path}/delete/${var.kv_group_name}/${each.key}/*" {
        capabilities = ["update"]
    }
    path "${var.kv_path}/undelete/${var.kv_group_name}/${each.key}*" {
        capabilities = ["update"]
    }
    path "k${var.kv_path}/undelete/${var.kv_group_name}/${each.key}/*" {
        capabilities = ["update"]
    }
EOT

}

output "policies" {
  value = local.policies
}
