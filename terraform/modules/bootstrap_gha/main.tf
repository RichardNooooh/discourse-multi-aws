
resource "aws_iam_openid_connect_provider" "github" {
  url            = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]
}

data "aws_iam_policy_document" "gha_trust" {
  statement {
    sid     = "GitHubOIDC"
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:${var.github_repository}:*"]
    }
  }
}

# ################## #
# Terraform/Tofu IAM #
# ################## #
resource "aws_iam_role" "gha_terraform" {
  name                 = "gha-iam-role"
  assume_role_policy   = data.aws_iam_policy_document.gha_trust.json
  max_session_duration = 3600 # secs
  description          = "GitHub Actions role for Terraform/Terragrunt CI"
  path                 = "/"
}




# ########## #
# Packer IAM #
# ########## #
