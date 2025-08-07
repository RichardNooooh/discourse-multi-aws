
variable "project" {
  type = string
}

variable "region" {
  type = string
}

variable "environment" {
  type = string
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

variable "iam_instance_profile_arn" {
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
