
include "root" {
  path = find_in_parent_folders("root.hcl")
  expose = true
}

locals {
  region = include.root.locals.region
}

terraform {
    source = "../../../../modules/network"
}

inputs = {
  region = local.region
  environment = "dev"
  extra_tags = {
    Environment = "dev"
  }
}
