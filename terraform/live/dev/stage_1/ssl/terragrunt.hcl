
include "root" {
  path = find_in_parent_folders("root.hcl")
  expose = true
}

locals {
  project = include.root.locals.project
  region = include.root.locals.region
  environment = include.root.locals.environment
}

terraform {
    source = "../../../../modules/ssl"
}

inputs = {
  project = local.project
  region = local.region
  environment = local.environment
}
