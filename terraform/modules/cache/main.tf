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
  name_prefix = "${local.name}-valkey-sg-"
  vpc_id      = var.vpc_id
  tags        = local.tags
}

# provides the `aws` cli by default, just need to install Valkey and/or docker(?)
data "aws_ami" "amazon_linux" {
  owners      = ["amazon"]
  most_recent = true
  name_regex  = "^al2023-ami-kernel-default-arm64"
}

resource "aws_launch_template" "valkey-template" {
  name          = "${local.name}-template"
  image_id      = data.aws_ami.amazon_linux.id
  instance_type = var.instance_type

  user_data = base64encode(
    templatefile("${path.module}/scripts/user_data.tftpl", {
      record_name    = var.record_name
      hosted_zone_id = var.hosted_zone_id
    })
  )

  vpc_security_group_ids = [aws_security_group.valkey-sg.id]

  iam_instance_profile { # TODO setup
    arn = var.iam_instance_profile_arn
  }

  credit_specification {
    cpu_credits = "standard"
  }

  metadata_options {
    http_tokens = "required"
  }

  tag_specifications {
    resource_type = "instance"
    tags          = local.tags
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
  health_check_grace_period = 300

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
