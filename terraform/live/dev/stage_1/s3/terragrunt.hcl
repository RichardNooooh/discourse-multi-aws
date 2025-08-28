
include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

locals {
  project     = include.root.locals.project
  environment = include.root.locals.environment
}

terraform {
  source = "../../../../modules/s3"
}

inputs = {
  project     = local.project
  environment = local.environment

  force_destroy = true
}
