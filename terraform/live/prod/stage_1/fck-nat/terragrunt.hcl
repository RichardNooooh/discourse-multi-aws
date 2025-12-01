
include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

locals {
  project     = include.root.locals.project
  environment = include.root.locals.environment
}

dependency "network" {
  config_path = "../network"
  mock_outputs = {
    vpc_id                  = "vpc-00000000"
    public_subnets          = ["subnet-aaaa1111", "subnet-bbbb2222"]
    private_route_table_ids = ["rtb-1111aaaa", "rtb-2222bbbb"]
    azs                     = ["us-nowherea", "us-nowhereb"]
  }
  mock_outputs_allowed_terraform_commands = ["init", "validate", "fmt"]
}

terraform {
  source = "../../../../modules/fck-nat"
}

inputs = {
  project     = local.project
  environment = local.environment

  vpc_id                  = dependency.network.outputs.vpc_id
  public_subnets          = [dependency.network.outputs.public_subnets[0]]          # just have the first AZ have this
  private_route_table_ids = [dependency.network.outputs.private_route_table_ids[0]] # TODO check...
  azs                     = [dependency.network.outputs.azs[0]]

  fcknat_instance = "t4g.nano"
}
