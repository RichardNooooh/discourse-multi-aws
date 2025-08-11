
variable "project" {
  type = string
}

variable "region" {
  type = string
}

variable "environment" {
  type = string
}

variable "extra_tags" {
  type    = map(string)
  default = {}
}

variable "vpc_id" {
  type = string
}

variable "engine_version" {
  type = string
}

variable "db_parameter_group_name" {
  type    = string
}

variable "db_parameter_group_major_version" {
  type    = string
}

variable "instance_size" {
  type = string
}

variable "database_subnet_group" {
  type = string
}

variable "sg_db_id" {
  type = string
}

variable "max_allocated_storage" {
  type    = number
  default = 100
}

variable "db_password" {
  type      = string
  sensitive = true
}

variable "multi_az" {
  type    = bool
  default = false
}

variable "hosted_zone_id" {
  type = string
}

variable "record_name" {
  type = string
}

