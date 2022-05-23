provider "vault" {
  address = var.vault_address
}

provider "aws" {}

provider "external" {}