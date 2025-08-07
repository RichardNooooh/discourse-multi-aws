locals {
  name     = "${var.project}-${var.environment}-vpc"
  vpc_cidr = "10.0.0.0/16"
  azs      = ["${var.region}a", "${var.region}b"]

  public_subnets   = ["10.0.0.0/24", "10.0.1.0/24"]   # "10.0.2.0/24", "10.0.3.0/24"
  private_subnets  = ["10.0.16.0/24", "10.0.17.0/24"] # "10.0.18.0/24", "10.0.19.0/24"
  database_subnets = ["10.0.32.0/24", "10.0.33.0/24"] # "10.0.34.0/24", "10.0.35.0/24"

  public_subnet_names   = ["${local.name}-public-net-1", "${local.name}-public-net-2"]
  private_subnet_names  = ["${local.name}-private-net-1", "${local.name}-private-net-2"]
  database_subnet_names = ["${local.name}-db-net-1", "${local.name}-db-net-2"]

  tags = merge(
    {
      Project     = var.project
      Environment = var.environment
    },
    var.extra_tags
  )
}

module "vpc" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-vpc.git?ref=v6.0.1"

  name             = "${local.name}-${var.environment}" # discourse-vpc-dev, -prod
  cidr             = local.vpc_cidr
  azs              = local.azs
  public_subnets   = local.public_subnets
  private_subnets  = local.private_subnets
  database_subnets = local.database_subnets

  public_subnet_names   = local.public_subnet_names
  private_subnet_names  = local.private_subnet_names
  database_subnet_names = local.database_subnet_names

  enable_nat_gateway = false # using fck-nat
  enable_vpn_gateway = false # too expensive

  enable_dns_support   = true
  enable_dns_hostnames = true

  create_database_subnet_group  = true # needed for rds
  manage_default_network_acl    = false
  manage_default_route_table    = false
  manage_default_security_group = false

  enable_flow_log = false # can get expensive!! default false, but just in case it's set false

  tags = local.tags
}

module "vpc-endpoints" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-vpc.git//modules/vpc-endpoints?ref=v6.0.1"
  vpc_id = module.vpc.vpc_id

  endpoints = {
    s3 = {
      service         = "s3"
      service_type    = "Gateway"
      route_table_ids = flatten([module.vpc.private_route_table_ids, module.vpc.public_route_table_ids])
      tags            = local.tags
    }
  }
}

# private Route53 zone for cache and database
resource "aws_route53_zone" "private" {
  name = "${var.project}.internal"
  vpc {
    vpc_id = module.vpc.vpc_id
  }
  tags = local.tags
}

