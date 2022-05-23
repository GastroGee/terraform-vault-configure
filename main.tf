# // pass a list of AWS accounts and create AWS auth backend and vault policy for read only and admin 

module "aws_admin" {
  source       = "./modules/aws"
  role_name    = "administrator"
  aws_accounts = var.account_name_map
}

module "aws_readonly" {
  source       = "./modules/aws"
  role_name    = "readonly"
  aws_accounts = var.account_name_map
}

module "aws_readwrite" {
  source       = "./modules/aws"
  role_name    = "readwrite"
  aws_accounts = var.account_name_map
}

// Create kv2 paths for a list of services such that each service has permission to write 
module "kv_services" {
  source        = "./modules/kv_policies"
  services      = var.services
  kv_group_name = var.kv_group_name
  kv_path       = "kv2" # so basically path will be `kv2/services/<service name>/`

}

module "ssh_client_signer" {
  source             = "./modules/ssh_client_signer"
  default_user       = "ubuntu"
  service_name       = "concourse"
}

// Set up PKI engine for Nomad mTLS
module "pki" {
  source = "./modules/pki"
}

// Set up Nomad Backend 
module "nomad" {
    source = "./modules/nomad"
    nomad_addr = var.nomad_addr
    nomad_token = var.nomad_token
}