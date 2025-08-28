
include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

locals {
  project     = include.root.locals.project
  environment = include.root.locals.environment
}

dependency "network" {
  config_path = "../../stage_1/network"
  mock_outputs = {
    vpc_id          = "vpc-00000000"
    public_subnets  = ["subnet-aaaa1111", "subnet-bbbb2222"]
    private_subnets = ["subnet-1111aaaa", "subnet-2222bbbb"]
  }
  mock_outputs_allowed_terraform_commands = ["init", "validate", "fmt"]
}

dependency "s3" {
  config_path = "../../stage_1/s3"
  mock_outputs = {
    s3_telemetry_bucket_id = "bucket-69696969"
  }
  mock_outputs_allowed_terraform_commands = ["init", "validate", "fmt"]
}

dependency "ssl" {
  config_path = "../../stage_1/ssl"
  mock_outputs = {
    acm_certificate_arn = "arn:::asdfasdfasdf"
  }
  mock_outputs_allowed_terraform_commands = ["init", "validate", "fmt"]
}

dependency "security" {
  config_path = "../../stage_1/security"
  mock_outputs = {
    webonly_iam_instance_arn = "arn:::asdfasdfasdf"
    sg_alb_id                = "sg-afasdfasfawe"
    sg_web_id                = "sg-asdfasdfasdf"
  }
}

terraform {
  source = "../../../../modules/app"
}

inputs = {
  project     = local.project
  environment = local.environment

  vpc_id          = dependency.network.outputs.vpc_id
  public_subnets  = dependency.network.outputs.public_subnets
  private_subnets = dependency.network.outputs.private_subnets

  s3_telemetry_bucket_id = dependency.s3.outputs.s3_telemetry_bucket_id

  acm_certificate_arn = dependency.ssl.outputs.acm_certificate_arn
  # cloudflare_zone_id is provided by environmental variable

  webonly_iam_instance_arn = dependency.security.outputs.webonly_iam_instance_arn
  sg_alb_id                = dependency.security.outputs.sg_alb_id
  sg_web_id                = dependency.security.outputs.sg_web_id

  webonly_instance_type = "t4g.small"
  min_size              = 1
  desired_capacity      = 2
  max_size              = 4
}
