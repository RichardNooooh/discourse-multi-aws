locals {
  name = "${var.project}-${var.environment}-db"
  tags = merge(
    {
      Project     = var.project,
      Environment = var.environment
    },
    var.extra_tags
  )
}

# ####################################### #
# ACM SSL Certificate with CloudFlare DNS #
# ####################################### #
resource "aws_acm_certificate" "this" {
  domain_name       = var.hostname
  subject_alternative_names = ["www.${var.hostname}"]
  validation_method = "DNS"

  tags = local.tags

  lifecycle {
    create_before_destroy = true
  }
}

locals {
  # https://github.com/cloudflare/terraform-provider-cloudflare/issues/154
  # https://mwop.net/blog/2024-09-20-acm-cloudflare-dns-validation.html
  acm_dvo = {
    for dvo in aws_acm_certificate.example.domain_validation_options : dvo.domain_name => {
      name   = trimsuffix(dvo.resource_record_name, ".")
      record = dvo.resource_record_value
      type   = trimsuffix(dvo.resource_record_type, ".")
    }
  }
}

resource "cloudflare_dns_record" "acm_validation" {
  for_each = local.acm_dvo

  zone_id = var.cloudflare_zone_id
  ttl     = 1 # automatic

  comment = "AWS ACM SSL Validation"

  name    = each.value.name
  type    = each.value.type
  content = each.value.record
  
  tags = ["managed:opentofu"]
}

resource "aws_acm_certificate_validation" "this" {
  certificate_arn = aws_acm_certificate.this.arn
  validation_record_fqdns = [for v in local.acm_dvo : v.name]
  depends_on = [ cloudflare_dns_record.acm_validation ]
}



