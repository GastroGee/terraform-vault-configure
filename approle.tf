# # # // Provide a list of service names and generate an approle for each for which a secret ID can be generated against
# # # // a service-to-policies map is also passed in to create policies for the approle
resource "vault_approle_auth_backend_role" "service" {
  for_each  = local.services
  backend   = "approle"
  role_name = each.key

// Lets tie each KV policy to their corresponding service approle
  token_policies = ["kv2-services-${each.key}-read", "kv2-services-${each.key}-write", vault_policy.github_token_generator.name]

  token_ttl = "43200" # Vault tokens generated via Approle/SecretId should expire after 12hr when not renewed

  token_max_ttl = "172800" # 2 days 

  secret_id_ttl = "21600" # Maybe more but note that some services might rely on secret_id not expiring
}


resource "vault_policy" "approle_secret_creation" {
  for_each = local.services
  name     = "approle-${each.key}-secret-creation"
  policy   = <<EOT
    path "auth/approle/role/${each.key}/*" {
        capabilities = ["create", "update","read"]
        }

        # Allow generation of child tokens 
        path "auth/token/create" {
            capabilities = ["create", "read", "update"]
        }
   EOT
}

