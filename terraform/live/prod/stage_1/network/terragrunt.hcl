
include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

locals {
  project     = include.root.locals.project
  environment = include.root.locals.environment
  region      = include.root.locals.region
}

terraform {
  source = "../../../../modules/network"
}

inputs = {
  project     = local.project
  environment = local.environment
  region      = local.region
}
