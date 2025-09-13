locals {
  name = "${var.project}-${var.environment}-db"
  tags = merge(
    {
      Project     = var.project,
      Environment = var.environment
      Managed     = "true"
    },
    var.extra_tags
  )
}

module "postgres_rds" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-rds.git?ref=v6.12.0"

  identifier               = local.name
  engine                   = "postgres"
  engine_version           = var.engine_version
  engine_lifecycle_support = "open-source-rds-extended-support-disabled" # expensive if enabled!!
  instance_class           = var.instance_size

  skip_final_snapshot = var.skip_final_snapshot

  family                 = var.db_parameter_group_name
  major_engine_version   = var.db_parameter_group_major_version
  db_subnet_group_name   = var.database_subnet_group
  vpc_security_group_ids = [var.sg_db_id]

  apply_immediately     = true
  allocated_storage     = 20
  max_allocated_storage = var.max_allocated_storage
  storage_type          = "gp3"

  db_name  = "discourse"
  username = "postgres"
  password = var.db_password

  manage_master_user_password = false
  deletion_protection         = false # TODO 

  # 12:00AM CST - 06:00AM CST
  backup_window           = "05:00-08:00"
  maintenance_window      = "Sun:08:00-Sun:11:00"
  backup_retention_period = 3

  multi_az = var.multi_az # TODO tags
}

resource "aws_route53_record" "db_cname" {
  zone_id = var.hosted_zone_id
  name    = var.record_name
  type    = "CNAME"
  ttl     = 300
  records = [module.postgres_rds.db_instance_address]
}
