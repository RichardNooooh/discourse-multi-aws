
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
    database_subnet_group  = "subnet-group-blahblahblah"
    vpc_id                 = "vpc-00000000"
    private_hosted_zone_id = "zone-id-00000000"
  }
  mock_outputs_allowed_terraform_commands = ["init", "validate", "fmt"]
}

dependency "security" {
  config_path = "../security"
  mock_outputs = {
    sg_db_id = "sg-blahblahblahblah"
  }
  mock_outputs_allowed_terraform_commands = ["init", "validate", "fmt"]
}

dependency "nat" {
  config_path  = "../fck-nat"
  mock_outputs = {}
}

terraform {
  source = "../../../../modules/database"
}

inputs = {
  project     = local.project
  region      = local.region
  environment = local.environment

  vpc_id         = dependency.network.outputs.vpc_id
  hosted_zone_id = dependency.network.outputs.private_hosted_zone_id
  record_name    = "db.discourse.internal"

  engine_version                   = "15.13"
  db_parameter_group_name          = "postgres15"
  db_parameter_group_major_version = "15"
  database_subnet_group            = dependency.network.outputs.database_subnet_group
  sg_db_id                         = dependency.security.outputs.sg_db_id

  max_allocated_storage = 1024
  multi_az              = false

  instance_size = "db.t4g.micro"
}
