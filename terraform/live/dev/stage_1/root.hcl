
locals {
  region = "us-west-2"
  state_bucket = get_env("TG_state_bucket")
  # cloudflare_api_token = get_env("TG_cloudflare_api_token")
}

remote_state {
  backend = "s3"

  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }

  config = {
    bucket = local.state_bucket

    key            = "dev/stage_1/${path_relative_to_include()}/tofu.tfstate"
    region         = local.region
    encrypt        = true
    use_lockfile   = true
  }
}

# provider "cloudflare" {
#   api_token = ${local.cloudflare_api_token}
# }

generate "provider" {
  path = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents = <<EOF
provider "aws" {
  region = "${local.region}"
}
EOF
}

# inputs = {

# }
