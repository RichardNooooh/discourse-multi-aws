## Inputs

| Name | Description | Type | Default | Required |
|-----|-----|-----|-----|-----|
| `vpc_id` | ID of VPC | string | `null` | yes |
| `public_subnets` | IDs of public subnets | list(string) | `null` | yes |
| `private_route_table_ids` | IDs of private route tables | list(string) | `null` | yes |
| `fcknat_instance` | EC2 instance type for `fck-nat` | string | `t4g.nano` | no |
| `ssh_key_name` | Name of SSH Key to access `fck-nat` instances | string | `null` | no | 