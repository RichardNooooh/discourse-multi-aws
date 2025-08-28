# VPC for Discourse

Standardized wrapper around the `terraform-aws-vpc` module to maintain consistent naming and environment schemes.

## Requirements

| Name | Version |
|------|---------|
| `terraform` | >= 1.0 |
| `aws` | ~> 6.10 |

## Providers

| Name | Version |
|------|---------|
| `aws` | ~> 6.10 |

## Modules

| Name | Version |
|------|---------|
| `terraform-aws-vpc` | ~> 6.10 |
| `terraform-aws-vpc//modules/vpc-endpoints` | ~> 6.10 |
| `terraform-aws-fck-nat` | >= 1.3 |

## Inputs

| Name | Description | Type | Default | Required |
|-----|-----|-----|-----|-----|
| `region` | AWS region | `string` | `null` | yes |
| `environment` | Suffix to denote `dev` or `prod` environment | `string` | `null` | yes | 
| `extra_tags` | Extra tags | map(string) | `{}` | no | 

## Outputs

| Name | Description |
|-----|-----|
| `vpc_id` | ID of new VPC |
| `azs` | Availability zones of this VPC
| `public_subnets` | IPs of public subnets |
| `private_subnets` | IPs of private subnets |
| `private_route_table_ids` | IDs of private route tables |
