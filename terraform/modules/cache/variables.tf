
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

variable "vpc_id" {
  type = string
}

variable "private_subnet_id" { # only one subnet
  type = string
}

variable "instance_type" {
  type = string
}

variable "sg_cache_id" {
  type = string
}

variable "cache_iam_instance_arn" {
  type = string
}

variable "hosted_zone_id" {
  type = string
}

variable "record_name" {
  type = string
}

variable "extra_tags" {
  type    = map(string)
  default = {}
}
