
include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

locals {
  project     = include.root.locals.project
  environment = include.root.locals.environment
}

terraform {
  source = "../../../../modules/ssl"
}

inputs = {
  project     = local.project
  environment = local.environment
  # cloudflare_zone_id provided by environmental variable
}
