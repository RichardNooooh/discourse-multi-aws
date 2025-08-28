
output "cloudflare_prefix_list_id" {
  description = "Managed Prefix List of CloudFlare"
  value       = aws_ec2_managed_prefix_list.cloudflare_ipv4.id
}

output "acm_certificate_arn" {
  description = "ARN of ACM Certificate"
  value       = aws_acm_certificate.this.arn
}

output "domain_name" {
  value     = aws_acm_certificate.this.domain_name
  sensitive = true
}
