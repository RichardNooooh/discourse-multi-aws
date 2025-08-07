locals {
  name = "${var.project}-${var.environment}-cache"
  tags = merge(
    {
      Project     = var.project,
      Environment = var.environment
    },
    var.extra_tags
  )
}

resource "aws_security_group" "valkey-sg" {
  name_prefix = "${local.name}-sg-"
  vpc_id      = var.vpc_id
  tags        = local.tags

  # temporary
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

# provides the `aws` cli by default, just need to install Valkey and/or docker(?)
data "aws_ami" "amazon_linux" {
  owners      = ["amazon"]
  most_recent = true
  filter {
    name = "name"
    values = ["al2023-ami-ecs-hvm-*-arm64"]
  }
}

resource "aws_launch_template" "valkey-template" {
  name          = "${local.name}-template"
  image_id      = data.aws_ami.amazon_linux.id
  instance_type = var.instance_type

  user_data = base64encode(
    templatefile("${path.module}/scripts/user_data.tftpl", {
      RECORD_NAME    = var.record_name
      HOSTED_ZONE_ID = var.hosted_zone_id
    })
  )

  vpc_security_group_ids = [aws_security_group.valkey-sg.id]

  iam_instance_profile {
    arn = aws_iam_instance_profile.cache.arn
  }

  credit_specification {
    cpu_credits = "standard"
  }

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  tag_specifications {
    resource_type = "instance"
    tags          = local.tags
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = local.tags
}

module "valkey-asg" {
  source              = "git::https://github.com/terraform-aws-modules/terraform-aws-autoscaling?ref=v9.0.1"
  name                = local.name
  vpc_zone_identifier = [var.private_subnet_id]

  # maintain a single Valkey cache node
  min_size         = 1
  max_size         = 1
  desired_capacity = 1

  health_check_type         = "EC2"
  health_check_grace_period = 150

  create_launch_template  = false
  launch_template_id      = aws_launch_template.valkey-template.id
  launch_template_version = "$Latest"

  tags = local.tags
}

# placeholder - should automatically write over this
resource "aws_route53_record" "valkey" {
  zone_id         = var.hosted_zone_id
  name            = var.record_name
  type            = "A"
  ttl             = 30
  records         = ["0.0.0.0"]
  allow_overwrite = true

  lifecycle {
    ignore_changes = [records] # Tofu won’t revert instance-set IPs
  }
}

# ############################# #
# IAM Role and Instance Profile #
# ############################# #
data "aws_iam_policy_document" "cache_assume_role" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "cache" {
  name = "${local.name}-iam-role"
  assume_role_policy = data.aws_iam_policy_document.cache_assume_role.json
  tags = local.tags
}

resource "aws_iam_instance_profile" "cache" {
  name = "${local.name}-iam-profile"
  role = aws_iam_role.cache.name
  tags = local.tags
}

resource "aws_iam_role_policy_attachment" "ssm_core" {
  role = aws_iam_role.cache.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Not sure if this is needed for Prometheus monitoring
# resource "aws_iam_role_policy_attachment" "cw_agent" {
#   role       = aws_iam_role.cache_assume_role.name
#   policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
# }

# ##################### #
# Route53 UPSERT Policy #
# ##################### #
data "aws_iam_policy_document" "route53_upsert" {
  statement {
    effect = "Allow"
    actions   = [
      "route53:ChangeResourceRecordSets",
      "route53:GetHostedZone",
      "route53:ListResourceRecordSets"
    ]
    resources = [
      "arn:aws:route53:::hostedzone/${var.hosted_zone_id}"
    ]
  }
}

resource "aws_iam_policy" "route53_upsert" {
  name = "${local.name}-iam-route53upsert"
  policy = data.aws_iam_policy_document.route53_upsert.json
  tags = local.tags
}

resource "aws_iam_role_policy_attachment" "route53_upsert_attach" {
  role = aws_iam_role.cache.name
  policy_arn = aws_iam_policy.route53_upsert.arn
}
