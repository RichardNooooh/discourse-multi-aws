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

# ####################### #
# CloudFlare IP Whitelist #
# ####################### #
data "http" "cloudflare_ips" {
  url = "https://api.cloudflare.com/client/v4/ips"
}

locals {
  ipv4_cidrs = toset(jsondecode(data.http.cloudflare_ips.response_body).result.ipv4_cidrs)
}

resource "aws_ec2_managed_prefix_list" "cloudflare_ipv4" {
  name           = "CloudFlare-IPv4"
  address_family = "IPv4"
  max_entries    = length(local.ipv4_cidrs)
  tags           = local.tags
}

resource "aws_ec2_managed_prefix_list_entry" "cloudflare_ipv4" {
  for_each       = local.ipv4_cidrs
  cidr           = each.key
  prefix_list_id = aws_ec2_managed_prefix_list.cloudflare_ipv4.id
  description    = "CloudFlare IPv4 CIDR Block"
}


# ####################################### #
# ACM SSL Certificate with CloudFlare DNS #
# ####################################### #
resource "aws_acm_certificate" "this" {
  domain_name               = var.hostname
  subject_alternative_names = ["www.${var.hostname}"]
  validation_method         = "DNS"

  tags = local.tags

  lifecycle {
    create_before_destroy = true
  }
}

locals {
  # https://github.com/cloudflare/terraform-provider-cloudflare/issues/154
  # https://mwop.net/blog/2024-09-20-acm-cloudflare-dns-validation.html
  acm_dvo = {
    for dvo in aws_acm_certificate.this.domain_validation_options : dvo.domain_name => {
      name   = trimsuffix(dvo.resource_record_name, ".")
      record = dvo.resource_record_value
      type   = trimsuffix(dvo.resource_record_type, ".")
    }
  }
}

resource "cloudflare_dns_record" "acm_validation" {
  for_each = local.acm_dvo

  zone_id = var.cloudflare_zone_id

  name    = each.value.name
  type    = each.value.type
  content = each.value.record
  ttl     = 1 # automatic

  # tags    = ["managed:opentofu"] # tags are only available for paid plans
  comment = "AWS ACM SSL Validation"
}

resource "aws_acm_certificate_validation" "this" {
  certificate_arn         = aws_acm_certificate.this.arn
  validation_record_fqdns = [for v in local.acm_dvo : v.name]
  depends_on              = [cloudflare_dns_record.acm_validation]
}

