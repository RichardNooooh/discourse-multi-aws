output "vpc_id" {
  description = "ID of new VPC"
  value       = module.vpc.vpc_id
}

output "azs" {
  description = "Availability zones of this VPC"
  value       = local.azs
}

output "public_subnets" {
  description = "IDs of public subnets"
  value       = module.vpc.public_subnets
}

output "private_subnets" {
  description = "IDs of private subnets"
  value       = module.vpc.private_subnets
}

output "private_route_table_ids" {
  description = "IDs of private route tables"
  value       = module.vpc.private_route_table_ids
}

output "private_hosted_zone_id" {
  description = "Zone ID of private hosted zone"
  value       = aws_route53_zone.private.zone_id
}

output "database_subnet_group" {
  value = module.vpc.database_subnet_group_name
}

