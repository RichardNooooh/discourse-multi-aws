
variable "project" {
  type     = string
  nullable = false
}

variable "environment" {
  type     = string
  nullable = false
  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "environment must be one of: dev, prod."
  }
}

variable "extra_tags" {
  type    = map(string)
  default = {}
}

variable "vpc_id" {
  type = string
}

variable "cloudflare_prefix_list_id" {
  type = string
}

variable "hosted_zone_id" {
  type = string
}

variable "s3_uploads_bucket_arn" { # TODO test if we can hide this with the sensitive field
  type = string
}

variable "s3_backups_bucket_arn" {
  type = string
}
