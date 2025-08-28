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

# provides the `aws` cli by default, just need to install Valkey and/or docker(?)
data "aws_ami" "amazon_linux" {
  owners      = ["amazon"]
  most_recent = true
  filter {
    name   = "name"
    values = ["al2023-ami-ecs-hvm-*-arm64"]
  }
}

resource "aws_launch_template" "valkey_template" {
  name                   = "${local.name}-template"
  image_id               = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  update_default_version = true

  user_data = base64encode(
    templatefile("${path.module}/scripts/user_data.tftpl", {
      RECORD_NAME    = var.record_name
      HOSTED_ZONE_ID = var.hosted_zone_id
    })
  )

  block_device_mappings {
    device_name = "/dev/sdf"

    ebs {
      delete_on_termination = true
      volume_size           = 12
      volume_type           = "gp3"
    }
  }

  vpc_security_group_ids = [var.sg_cache_id]

  iam_instance_profile {
    arn = var.cache_iam_instance_arn
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
  launch_template_id      = aws_launch_template.valkey_template.id
  launch_template_version = aws_launch_template.valkey_template.latest_version

  instance_refresh = {
    strategy = "Rolling"
    preferences = {
      min_healthy_percentage = 0
      max_healthy_percentage = 100
      instance_warmup        = 120
    }
    skip_matching = false
  }

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
