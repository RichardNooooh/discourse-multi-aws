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

variable "environment" {
  type = string
}

variable "db_password" {
  type      = string
  sensitive = true
}

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
