
include "root" {
  path = find_in_parent_folders("root.hcl")
  expose = true
}

locals {
  region = include.root.locals.region
}

dependency "network" {
  config_path = "../network"
  mock_outputs = {
    vpc_id                  = "vpc-00000000"
    public_subnets          = ["subnet-aaaa1111", "subnet-bbbb2222"]
    private_route_table_ids = ["rtb-1111aaaa", "rtb-2222bbbb"]
    azs                     = ["${local.region}a", "${local.region}b"]
  }
}

terraform {
    source = "../../../../modules/fck-nat"
}

inputs = {
  region = local.region
  environment = "dev" # TODO refactor

  vpc_id                  = dependency.network.outputs.vpc_id
  public_subnets          = dependency.network.outputs.public_subnets
  private_route_table_ids = dependency.network.outputs.private_route_table_ids
  azs                     = dependency.network.outputs.azs

  extra_tags = {
    Environment = "dev" # TODO refactor
  }
}
