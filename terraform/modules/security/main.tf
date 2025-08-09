locals {
  name = "${var.project}-${var.environment}"

  tags = merge(
    {
      Project     = var.project,
      Environment = var.environment
    },
    var.extra_tags
  )
}

# ############### #
# Security Groups #
# ############### #
resource "aws_security_group" "alb" {
  name = "alb-sg-${local.name}"
  description = "ALB"
  vpc_id = var.vpc_id
  tags = local.tags
}

resource "aws_security_group" "web" {
  name = "web-sg-${local.name}"
  description = "web-only containers"
  vpc_id = var.vpc_id
  tags = local.tags
}

resource "aws_security_group" "metrics" { # TODO
  name = "metrics-sg-${local.name}"
  description = "Monitoring stack"
  vpc_id = var.vpc_id
  tags = local.tags
}

resource "aws_security_group" "cache" {
  name = "cache-sg-${local.name}"
  description = "Valkey/Redis instance"
  vpc_id = var.vpc_id
  tags = local.tags
}

resource "aws_security_group" "db" {
  name = "db-sg-${local.name}"
  description = "PostgreSQL database"
  vpc_id = var.vpc_id
  tags = local.tags
}

# ############# #
# Ingress Rules #
# ############# #
resource "aws_vpc_security_group_ingress_rule" "alb_https_from_cloudflare" {
  security_group_id = aws_security_group.alb.id
  prefix_list_id    = var.cloudflare_prefix_list_id
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "alb_http_from_cloudflare" {
  security_group_id = aws_security_group.alb.id
  prefix_list_id    = var.cloudflare_prefix_list_id
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "web_http_from_alb" {
  security_group_id            = aws_security_group.web.id
  referenced_security_group_id = aws_security_group.alb.id
  from_port                    = 80
  to_port                      = 80
  ip_protocol                  = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "db_from_web" {
  security_group_id            = aws_security_group.db.id
  referenced_security_group_id = aws_security_group.web.id
  from_port                    = 5432
  to_port                      = 5432
  ip_protocol                  = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "cache_from_web" {
  security_group_id            = aws_security_group.cache.id
  referenced_security_group_id = aws_security_group.web.id
  from_port                    = 6379
  to_port                      = 6379
  ip_protocol                  = "tcp"
}

# ############ #
# Egress Rules #
# ############ #
resource "aws_vpc_security_group_egress_rule" "alb_http_to_web" {
  security_group_id            = aws_security_group.alb.id
  referenced_security_group_id = aws_security_group.web.id
  from_port                    = 80
  to_port                      = 80
  ip_protocol                  = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "web_https_to_internet" {
  security_group_id = aws_security_group.web.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "cache_https_to_internet" {
  security_group_id = aws_security_group.cache.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
}


