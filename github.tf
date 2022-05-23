// Create github token policy
// we could later assign this policy to a principal that allows them generate ephemeral tokens for github
data "vault_policy_document" "github-token-policy-doc" {
  rule {
    path         = "github/token"
    capabilities = ["update", "read"]
    description  = "Allow for creating ephemeral github tokens"
  }
}

resource "vault_policy" "github_token_generator" {
  name   = "github-token-generator"
  policy = data.vault_policy_document.github-token-policy-doc.hcl
}




