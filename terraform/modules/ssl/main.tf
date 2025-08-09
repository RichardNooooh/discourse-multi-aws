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

data "http" "cloudflare_ips" {
  url = "https://api.cloudflare.com/client/v4/ips" 
}

locals {
  ipv4_cidrs = toset(jsondecode(data.http.cloudflare_ips.response_body).result.ipv4_cidrs)
}

resource "aws_ec2_managed_prefix_list" "cloudflare_ipv4"{
  name = "CloudFlare-IPv4"
  address_family = "IPv4"
  max_entries = length(local.ipv4_cidrs)
  tags = local.tags
}

resource "aws_ec2_managed_prefix_list_entry" "cloudflare_ipv4" {
  for_each = local.ipv4_cidrs
  cidr = each.key
  prefix_list_id = aws_ec2_managed_prefix_list.cloudflare_ipv4.id
  description = "CloudFlare IPv4 CIDR Block"
}
