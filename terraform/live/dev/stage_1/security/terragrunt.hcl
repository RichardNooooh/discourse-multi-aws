
include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

locals {
  project     = include.root.locals.project
  region      = include.root.locals.region
  environment = include.root.locals.environment
}

dependency "network" {
  config_path = "../network"
  mock_outputs = {
    vpc_id                 = "vpc-00000000"
    private_hosted_zone_id = "zone-asdfasdfasdf"
  }
  mock_outputs_allowed_terraform_commands = ["init", "validate", "fmt"]
}

dependency "ssl" {
  config_path = "../ssl"
  mock_outputs = {
    cloudflare_prefix_list_id = ["69.210.0.0/20"]
  }
  mock_outputs_allowed_terraform_commands = ["init", "validate", "fmt"]
}

terraform {
  source = "../../../../modules/security"
}

inputs = {
  project     = local.project
  region      = local.region
  environment = local.environment

  vpc_id                    = dependency.network.outputs.vpc_id
  cloudflare_prefix_list_id = dependency.ssl.outputs.cloudflare_prefix_list_id
  hosted_zone_id            = dependency.network.outputs.private_hosted_zone_id
}
