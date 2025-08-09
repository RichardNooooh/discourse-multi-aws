
output "cloudflare_prefix_list_id" {
  description = "Managed Prefix List of CloudFlare"
  value = aws_ec2_managed_prefix_list.cloudflare_ipv4.id
}
