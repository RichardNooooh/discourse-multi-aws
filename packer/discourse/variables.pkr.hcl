variable "ami_prefix" {
  type = string
}

variable "build_instance" {
  type = string
}

variable "build_volume" {
  type = number
}

variable "aws_region" {
  type = string
}

variable "node_exporter_version" {
  type = string
}


# variable "environment" {
#   type = string
# }

# Terraform Variables
variable "vpc_id" {
  type = string
}

variable "subnet_id" {
  type = string
}

variable security_group_id {
  type = string
}

variable iam_instance_profile_name {
  type = string
}

# ALB IP Trust
variable "alb_subnet_ips" {
  type = list(string)
}

# Secrets
variable "HOSTNAME" {
  type      = string
  sensitive = true
}

variable "DEVELOPER_EMAILS" {
  type      = string
  sensitive = true
}

variable "SMTP_ADDRESS" {
  type      = string
  sensitive = true
}

variable "SMTP_PORT" {
  type      = string
  sensitive = true
}

variable "SMTP_USER_NAME" {
  type      = string
  sensitive = true
}

variable "SMTP_PASSWORD" {
  type      = string
  sensitive = true
}

variable "DB_PASSWORD" {
  type      = string
  sensitive = true
}

variable "S3_UPLOADS_BUCKET" {
  type      = string
  sensitive = true
}

variable "S3_BACKUPS_BUCKET" {
  type      = string
  sensitive = true
}

variable "MAXMIND_ACCOUNT_ID" {
  type      = string
  sensitive = true
}

variable "MAXMIND_LICENSE_KEY" {
  type      = string
  sensitive = true
}
