
variable "project" {
  type = string
}

variable "region" {
  type = string
}

variable "environment" { # dev or prod, or whatever
  type = string
}

variable "azs" {
  type = list(string)
}

variable "vpc_id" {
  type = string
}

variable "public_subnets" {
  type = list(string)
}

variable "private_route_table_ids" {
  type = list(string)
}

variable "fcknat_instance" {
  type    = string
}

variable "ssh_key_name" {
  type    = string
  default = null
}

variable "extra_tags" {
  type    = map(string)
  default = {}
}
