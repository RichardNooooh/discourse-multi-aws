locals {
  name = "${var.project}-${var.environment}-webonly"
  tags = merge(
    {
      Project     = var.project,
      Environment = var.environment
      Role        = "web"
      Managed     = "true"
    },
    var.extra_tags
  )
}

# ######################### #
# Application Load Balancer #
# ######################### #
module "alb" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-alb.git?ref=v9.17.0"

  name    = "${local.name}-alb"
  vpc_id  = var.vpc_id
  subnets = var.public_subnets

  enable_deletion_protection = false # TODO temporary
  create_security_group      = false
  security_groups            = [var.sg_alb_id]
  idle_timeout               = 90

  access_logs = { # TODO lifecycle rules on alb logs
    bucket  = var.s3_monitor_bucket_id
    enabled = true
    prefix  = "alb/access-logs"
  }

  connection_logs = {
    bucket  = var.s3_monitor_bucket_id
    enabled = true
    prefix  = "alb/connection-logs"
  }

  target_groups = {
    web_only = {
      name        = "${local.name}-tg"
      protocol    = "HTTP"
      port        = 80
      target_type = "instance"
      health_check = {
        enabled             = true
        healthy_threshold   = 5 # number of checks
        unhealthy_threshold = 5
        interval            = 15 # seconds
        timeout             = 5  # seconds
        matcher             = "200"
        path                = "/srv/status" # https://meta.discourse.org/t/health-check-api/119458
      }

      create_attachment = false
    }
  }

  listeners = {
    http = {
      port     = 80
      protocol = "HTTP"
      redirect = {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }
    https = {
      port            = 443
      protocol        = "HTTPS"
      ssl_policy      = "ELBSecurityPolicy-TLS13-1-2-2021-06"
      certificate_arn = var.acm_certificate_arn
      forward = {
        target_group_key = "web_only"
      }
    }
  }

  # health check on /srv/status, ensure no hits on `/`
  # https://meta.discourse.org/t/do-hits-to-srv-status-count-as-crawlers/143431
  tags = local.tags
}

locals {
  cloudflare_env_records = (var.environment == "prod") ? toset(["@", "www"]) : toset(["dev"])
}

resource "cloudflare_dns_record" "alb_record" {
  for_each = local.cloudflare_env_records

  zone_id = var.cloudflare_zone_id
  name    = each.value
  type    = "CNAME"
  content = module.alb.dns_name
  ttl     = 1 # automatic
  proxied = each.value == "www" ? true : var.cloudflare_proxied # www needs to be proxied for redirects
  comment = "Discourse Hostname Record - ${var.environment}"
}

resource "cloudflare_ruleset" "www_to_root" {
  count       = var.environment == "prod" ? 1 : 0
  zone_id     = var.cloudflare_zone_id
  name        = "Redirect WWW to apex"
  description = "WWW to apex"
  kind        = "zone"
  phase       = "http_request_dynamic_redirect"

  rules = [
    {
      action      = "redirect"
      description = "301 Redirect WWW to Root"
      
      expression  = "http.request.full_uri wildcard \"https://www.*\""

      action_parameters = {
        from_value = {
          status_code           = 301
          preserve_query_string = false

          target_url = {
            expression = "wildcard_replace(http.request.full_uri, \"https://www.*/\", \"https://$${1}\")"
          }
        }
      }

      enabled = true
    }
  ]
}

# ################# #
# Autoscaling Group #
# ##################
resource "aws_launch_template" "webonly_template" {
  name          = "${local.name}-template"
  image_id      = var.webonly_image_id
  instance_type = var.webonly_instance_type

  update_default_version = true
  vpc_security_group_ids = [var.sg_web_id]

  iam_instance_profile {
    arn = var.webonly_iam_instance_arn
  }

  credit_specification {
    cpu_credits = "standard"
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


module "asg" {
  source              = "git::https://github.com/terraform-aws-modules/terraform-aws-autoscaling?ref=v9.0.1"
  name                = "${local.name}"
  vpc_zone_identifier = var.private_subnets

  min_size         = var.min_size
  desired_capacity = var.desired_capacity
  max_size         = var.max_size

  health_check_type         = "ELB"
  health_check_grace_period = 150

  # connecting to ALB
  traffic_source_attachments = {
    ex-alb = {
      traffic_source_identifier = module.alb.target_groups["web_only"].arn
      traffic_source_type       = "elbv2"
    }
  }

  create_launch_template  = false
  launch_template_id      = aws_launch_template.webonly_template.id
  launch_template_version = aws_launch_template.webonly_template.latest_version

  instance_refresh = {
    strategy = "Rolling"
    preferences = {
      min_healthy_percentage = 0
      max_healthy_percentage = 100
      instance_warmup        = 120
    }
    skip_matching = false
  }

  scaling_policies = {
    avg-cpu-policy-greater-than-75 = {
      policy_type = "TargetTrackingScaling"
      target_tracking_configuration = {
        predefined_metric_specification = {
          predefined_metric_type = "ASGAverageCPUUtilization"
        }
        target_value = 75.0
      }
    } # TODO RAM scaling
  }

  tags = local.tags
}
