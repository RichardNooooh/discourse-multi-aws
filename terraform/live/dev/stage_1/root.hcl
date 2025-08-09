
locals {
  project = "discourse"
  region = "us-west-2"
  environment = "dev"
}

remote_state {
  backend = "s3"

  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }

  config = {
    bucket = get_env("TF_VAR_STATE_BUCKET")

    key            = "${local.environment}/stage_1/${path_relative_to_include()}/tofu.tfstate"
    region         = local.region
    encrypt        = true
    use_lockfile   = true
  }
}

generate "provider" {
  path = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents = <<EOF
provider "aws" {
  region = "${local.region}"
}

provider "cloudflare" {
  api_token = ${get_env("TF_VAR_CLOUDFLARE_API_TOKEN")}
}
EOF
}

# inputs = {

# }
