
variable "project" {
  type = string
}

variable "region" {
  type = string
}

variable "environment" { # dev or prod, or whatever
  type = string
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
