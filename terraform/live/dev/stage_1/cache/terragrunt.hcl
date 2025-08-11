
include "root" {
  path = find_in_parent_folders("root.hcl")
  expose = true
}

locals {
  project = include.root.locals.project
  region = include.root.locals.region
  environment = include.root.locals.environment
}

dependency "network" {
  config_path = "../network"
  mock_outputs = {
    vpc_id                 = "vpc-00000000"
    private_subnets        = ["subnet-aaaa1111"]
    private_hosted_zone_id = "zone-id-00000000"
  }
  mock_outputs_allowed_terraform_commands = ["init", "validate", "fmt"]
}

dependency "nat" {
  config_path = "../fck-nat"
  mock_outputs = {}
}

dependency "security" {
  config_path = "../security"
  mock_outputs = {
    sg_cache_id = "sg-blahblahblah"
    cache_iam_instance_arn = "instance-profile-asdfasdfasdfasdf"
  }
  mock_outputs_allowed_terraform_commands = ["init", "validate", "fmt"]
}

terraform {
    source = "../../../../modules/cache"
}

inputs = {
  project = local.project
  region = local.region
  environment = local.environment

  vpc_id             = dependency.network.outputs.vpc_id
  private_subnet_id  = dependency.network.outputs.private_subnets[0]
  hosted_zone_id     = dependency.network.outputs.private_hosted_zone_id
  record_name        = "cache.discourse.internal"

  instance_type      = "t4g.nano" # should be ARM64-based

  sg_cache_id = dependency.security.outputs.sg_cache_id
  cache_instance_arn = dependency.security.outputs.cache_iam_instance_arn
}
