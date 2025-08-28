locals {
  name = "${var.project}-${var.environment}"

  tags = merge( # TODO refactor this stupid thing
    {
      Project     = var.project,
      Environment = var.environment
    },
    var.extra_tags
  )
}

# #################### #
# IAM Policy Documents #
# #################### #
data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

# S3 IAM access
# https://meta.discourse.org/t/set-up-file-and-image-uploads-to-s3/7229/270
data "aws_iam_policy_document" "discourse_s3" {
  statement {
    effect = "Allow"
    actions = [
      "s3:List*",
      "s3:Get*",
      "s3:AbortMultipartUpload",
      "s3:DeleteObject",
      "s3:PutObject",
      "s3:PutObjectAcl",
      "s3:PutObjectVersionAcl",
      "s3:PutLifecycleConfiguration", # TODO check this
      # "s3:CreateBucket", # we already create the buckets
      "s3:PutBucketCORS"
    ]
    resources = [
      "${var.s3_uploads_bucket_arn}",
      "${var.s3_uploads_bucket_arn}/*",
      "${var.s3_backups_bucket_arn}",
      "${var.s3_backups_bucket_arn}/*",
    ]
  }
  statement {
    effect    = "Allow"
    actions   = ["s3:ListAllMyBuckets", "s3:ListBucket"]
    resources = ["*"]
  }
}

# https://developer.hashicorp.com/packer/integrations/hashicorp/amazon#iam-task-or-instance-role
# this is for GitHub Actions
# data "aws_iam_policy_document" "packer_policies" {
#   statement {
#     effect = "Allow"
#     actions = [
#       "ec2:AttachVolume",
#       "ec2:AuthorizeSecurityGroupIngress",
#       "ec2:CopyImage",
#       "ec2:CreateImage",
#       "ec2:CreateKeyPair",
#       "ec2:CreateSecurityGroup",
#       "ec2:CreateSnapshot",
#       "ec2:CreateTags",
#       "ec2:CreateVolume",
#       "ec2:DeleteKeyPair",
#       "ec2:DeleteSecurityGroup",
#       "ec2:DeleteSnapshot",
#       "ec2:DeleteVolume",
#       "ec2:DeregisterImage",
#       "ec2:DescribeImageAttribute",
#       "ec2:DescribeImages",
#       "ec2:DescribeInstances",
#       "ec2:DescribeInstanceStatus",
#       "ec2:DescribeRegions",
#       "ec2:DescribeSecurityGroups",
#       "ec2:DescribeSnapshots",
#       "ec2:DescribeSubnets",
#       "ec2:DescribeTags",
#       "ec2:DescribeVolumes",
#       "ec2:DetachVolume",
#       "ec2:GetPasswordData",
#       "ec2:ModifyImageAttribute",
#       "ec2:ModifyInstanceAttribute",
#       "ec2:ModifySnapshotAttribute",
#       "ec2:RegisterImage",
#       "ec2:RunInstances",
#       "ec2:StopInstances",
#       "ec2:TerminateInstances"
#     ]
#     resources = [
#       "*"
#     ]
#   }
# }

data "aws_iam_policy_document" "route53_upsert" {
  statement {
    effect = "Allow"
    actions = [
      "route53:ChangeResourceRecordSets",
      "route53:GetHostedZone",
      "route53:ListResourceRecordSets"
    ]
    resources = [
      "arn:aws:route53:::hostedzone/${var.hosted_zone_id}"
    ]
  }
}

# ############################ #
# IAM for `web_only` instances #
# ############################ #
resource "aws_iam_role" "webonly_iam" {
  name               = "${local.name}-webonly-iam-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json
  tags               = local.tags
}

resource "aws_iam_role_policy" "webonly_iam_s3" {
  role   = aws_iam_role.webonly_iam.id
  name   = "${local.name}-webonly-iam-s3-policy"
  policy = data.aws_iam_policy_document.discourse_s3.json
}

resource "aws_iam_role_policy_attachment" "webonly_iam_ssm_core" {
  role       = aws_iam_role.webonly_iam.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "webonly_iam_instance_profile" {
  name = "${local.name}-webonly-iam-instance"
  role = aws_iam_role.webonly_iam.name
}

# ######################### #
# IAM for `cache` instances #
# ######################### #
# assume_role_policy is the "trust" policy of who/what can *assume* this policy
resource "aws_iam_role" "cache_iam_role" {
  name               = "${local.name}-cache-iam-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json
  tags               = local.tags
}

resource "aws_iam_role_policy" "cache_route53_policy" {
  role   = aws_iam_role.cache_iam_role.id
  name   = "${local.name}-cache-iam-route53"
  policy = data.aws_iam_policy_document.route53_upsert.json
}

resource "aws_iam_role_policy_attachment" "cache_iam_ssm_core" {
  role       = aws_iam_role.cache_iam_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "cache_iam_instance_profile" {
  name = "${local.name}-cache-iam-instance"
  role = aws_iam_role.cache_iam_role.name
}

# # ######################## #
# # IAM for `packer` runner  #
# # ######################## #
#! Turns out the packer-specific policy is only needed by the box running Packer itself, i.e. GitHub Actions, not the temporary instance itself
# TODO

# ############### #
# Security Groups #
# ############### #
resource "aws_security_group" "alb" {
  name        = "${local.name}-alb-sg"
  description = "ALB"
  vpc_id      = var.vpc_id
  tags        = local.tags
}

resource "aws_security_group" "web" {
  name        = "${local.name}-web-sg"
  description = "web-only containers"
  vpc_id      = var.vpc_id
  tags        = local.tags
}

resource "aws_security_group" "telemetry" { # TODO
  name        = "${local.name}-telemetry-sg"
  description = "Monitoring stack"
  vpc_id      = var.vpc_id
  tags        = local.tags
}

resource "aws_security_group" "cache" {
  name        = "${local.name}-cache-sg"
  description = "Valkey/Redis instance"
  vpc_id      = var.vpc_id
  tags        = local.tags
}

resource "aws_security_group" "db" {
  name        = "${local.name}-db-sg"
  description = "PostgreSQL database"
  vpc_id      = var.vpc_id
  tags        = local.tags
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

resource "aws_vpc_security_group_egress_rule" "web_http_to_internet" {
  security_group_id = aws_security_group.web.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "web_https_to_internet" {
  security_group_id = aws_security_group.web.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "web_tcp_to_db" {
  security_group_id            = aws_security_group.web.id
  referenced_security_group_id = aws_security_group.db.id
  from_port                    = 5432
  to_port                      = 5432
  ip_protocol                  = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "web_tcp_to_cache" {
  security_group_id            = aws_security_group.web.id
  referenced_security_group_id = aws_security_group.cache.id
  from_port                    = 6379
  to_port                      = 6379
  ip_protocol                  = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "web_ntp_to_aws" {
  security_group_id = aws_security_group.web.id
  cidr_ipv4         = "169.254.169.123/32"
  from_port         = 123
  to_port           = 123
  ip_protocol       = "udp"
}

resource "aws_vpc_security_group_egress_rule" "cache_https_to_internet" {
  security_group_id = aws_security_group.cache.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "cache_http_to_internet" {
  security_group_id = aws_security_group.cache.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "cache_ntp_to_aws" {
  security_group_id = aws_security_group.cache.id
  cidr_ipv4         = "169.254.169.123/32"
  from_port         = 123
  to_port           = 123
  ip_protocol       = "udp"
}
